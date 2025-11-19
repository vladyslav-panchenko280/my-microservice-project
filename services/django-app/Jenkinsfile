pipeline {
    agent any

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
        timestamps()
    }

    parameters {
        string(name: 'BUILD_CONTEXT', defaultValue: 'services/django-app/django_app', description: 'Build context path')
        string(name: 'IMAGE_TAG', defaultValue: '', description: 'Image tag (defaults to environment-based tag)')
    }

    environment {
        AWS_REGION = 'us-east-1'
        AWS_ACCOUNT_ID = credentials('aws-account-id')
        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
    }

    stages {
        stage('Determine Environment') {
            steps {
                script {
                    // Determine environment based on branch
                    def branch = env.BRANCH_NAME ?: sh(script: 'git rev-parse --abbrev-ref HEAD', returnStdout: true).trim()

                    if (branch == 'main') {
                        env.DEPLOY_ENV = 'prod'
                        env.DOCKERFILE = 'Prod.Dockerfile'
                    } else if (branch == 'stage') {
                        env.DEPLOY_ENV = 'stage'
                        env.DOCKERFILE = 'Stage.Dockerfile'
                    } else if (branch == 'dev') {
                        env.DEPLOY_ENV = 'dev'
                        env.DOCKERFILE = 'Dev.Dockerfile'
                    } else {
                        env.DEPLOY_ENV = 'dev'
                        env.DOCKERFILE = 'Dev.Dockerfile'
                    }

                    env.ECR_REPO_NAME = "es-ecr-${env.DEPLOY_ENV}"
                    env.IMAGE_NAME = "${ECR_REGISTRY}/${ECR_REPO_NAME}"
                    env.IMAGE_TAG_FINAL = params.IMAGE_TAG ?: "django-${env.DEPLOY_ENV}-${BUILD_NUMBER}"

                    echo "Jenkins Pipeline: Docker Build and ECR Push"
                    echo "Branch: ${branch}"
                    echo "Environment: ${env.DEPLOY_ENV}"
                    echo "Dockerfile: ${env.DOCKERFILE}"
                    echo "AWS Account: ${AWS_ACCOUNT_ID}"
                    echo "ECR Registry: ${ECR_REGISTRY}"
                    echo "ECR Repository: ${ECR_REPO_NAME}"
                    echo "Image Tag: ${IMAGE_TAG_FINAL}"
                    echo "Full Image: ${IMAGE_NAME}:${IMAGE_TAG_FINAL}"
                }
            }
        }

        stage('Checkout') {
            steps {
                checkout scm
                sh '''
                    echo "Git commit: $(git rev-parse --short HEAD)"
                    echo "Git branch: $(git rev-parse --abbrev-ref HEAD)"
                '''
            }
        }

        stage('Build with Docker') {
            steps {
                sh '''
                    echo "Building Docker image with ${DOCKERFILE}..."
                    cd ${BUILD_CONTEXT}
                    docker build \
                        -f ${DOCKERFILE} \
                        -t ${IMAGE_NAME}:${IMAGE_TAG_FINAL} \
                        -t ${IMAGE_NAME}:django-${DEPLOY_ENV} \
                        --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
                        --build-arg VCS_REF=$(git rev-parse --short HEAD) \
                        --build-arg VERSION=${IMAGE_TAG_FINAL} \
                        .
                '''
            }
        }

        stage('Test Image') {
            steps {
                sh '''
                    echo "Testing Docker image..."
                    docker inspect ${IMAGE_NAME}:${IMAGE_TAG_FINAL}
                    echo "Image size: $(docker images --format "{{.Size}}" ${IMAGE_NAME}:${IMAGE_TAG_FINAL})"
                '''
            }
        }

        stage('Push to ECR') {
            steps {
                sh '''
                    echo "Authenticating with ECR..."
                    aws ecr get-login-password --region ${AWS_REGION} | \
                        docker login --username AWS --password-stdin ${ECR_REGISTRY}

                    echo "Pushing images to ECR..."
                    docker push ${IMAGE_NAME}:${IMAGE_TAG_FINAL}
                    docker push ${IMAGE_NAME}:django-${DEPLOY_ENV}

                    echo "Images successfully pushed to ECR"
                    echo "  - ${IMAGE_NAME}:${IMAGE_TAG_FINAL}"
                    echo "  - ${IMAGE_NAME}:django-${DEPLOY_ENV}"
                '''
            }
        }

        stage('Update Deployment Repo') {
            when {
                anyOf {
                    branch 'main'
                    branch 'stage'
                    branch 'dev'
                }
            }
            steps {
                script {
                    withCredentials([usernamePassword(
                        credentialsId: 'github-token',
                        usernameVariable: 'GIT_USER',
                        passwordVariable: 'GIT_PASS'
                    )]) {
                        sh '''
                            git config --global user.email "jenkins@example.com"
                            git config --global user.name "Jenkins CI/CD"

                            CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
                            echo "Current branch: ${CURRENT_BRANCH}"

                            DEPLOY_DIR=$(mktemp -d)
                            cd $DEPLOY_DIR

                            git clone -b ${CURRENT_BRANCH} https://${GIT_USER}:${GIT_PASS}@github.com/vladyslav-panchenko280/django-app.git .

                            VALUES_FILE="charts/django-app/values-${DEPLOY_ENV}.yaml"

                            if [ -f "$VALUES_FILE" ]; then
                                echo "Updating image tag in ${VALUES_FILE}..."

                                sed -i "s|tag: .*|tag: django-${DEPLOY_ENV}|g" $VALUES_FILE

                                if ! git diff --quiet; then
                                    git add $VALUES_FILE
                                    git commit -m "chore: update ${DEPLOY_ENV} image tag to django-${DEPLOY_ENV}

Build: ${BUILD_NUMBER}
Environment: ${DEPLOY_ENV}
Image: ${IMAGE_NAME}:django-${DEPLOY_ENV}
Commit: $(git rev-parse --short HEAD)"
                                    git push https://${GIT_USER}:${GIT_PASS}@github.com/vladyslav-panchenko280/django-app.git ${CURRENT_BRANCH}
                                    echo "Updated deployment repository on branch ${CURRENT_BRANCH}"
                                else
                                    echo "No changes to commit"
                                fi
                            else
                                echo "Values file not found: $VALUES_FILE"
                            fi
                        '''
                    }
                }
            }
        }
    }

    post {
        success {
            echo "Build succeeded"
            echo "Image: ${IMAGE_NAME}:${IMAGE_TAG_FINAL}"
        }
        failure {
            echo "Build failed - check logs"
        }
        cleanup {
            cleanWs()
        }
    }
}
