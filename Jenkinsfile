pipeline {
    agent any

    environment {
        DEV_REPO = "prabakaran90/devops-app-dev"
        PROD_REPO = "prabakaran90/devops-app-prod"
        IMAGE_TAG = "latest"
    }

    stages {
        stage('Clone Repository') {
            steps {
                script {
                    echo "Triggered by GitHub Webhook: Branch = ${env.BRANCH_NAME}"
                    git branch: env.BRANCH_NAME, url: 'https://github.com/psivasankaran1/devops-deployment.git'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def IMAGE_NAME = "${DEV_REPO}:${IMAGE_TAG}"

                    if (env.BRANCH_NAME == "master") {
                        echo "Merging dev into master - Using prod repo"
                        IMAGE_NAME = "${PROD_REPO}:${IMAGE_TAG}"
                    }

                    echo "Building Docker Image: $IMAGE_NAME"
                    sh "docker build -t $IMAGE_NAME ."
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                script {
                    def IMAGE_NAME = "${DEV_REPO}:${IMAGE_TAG}"

                    if (env.BRANCH_NAME == "master") {
                        echo "Pushing to production repo"
                        IMAGE_NAME = "${PROD_REPO}:${IMAGE_TAG}"
                    }

                    withDockerRegistry([credentialsId: 'docker-hub-credentials', url: '']) {
                        echo "Pushing Docker Image: $IMAGE_NAME"
                        sh "docker push $IMAGE_NAME"
                    }
                }
            }
        }

        stage('Deploy Application') {
            steps {
                script {
                    def DEPLOY_ENV = (env.BRANCH_NAME == "master") ? "prod" : "dev"
                    echo "Deploying ${DEPLOY_ENV} environment..."
                    sh "./deploy.sh ${DEPLOY_ENV}"
                }
            }
        }
    }

    post {
        success {
            echo "✅ Deployment successful!"
        }
        failure {
            echo "❌ Deployment failed. Check logs!"
        }
    }
}
