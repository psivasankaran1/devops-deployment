pipeline {
    agent any

    environment {
        DEV_REPO = "prabakaran90/devops-app-dev"
        PROD_REPO = "prabakaran90/devops-app-prod"
        IMAGE_TAG = "latest"

        // AWS Configuration
        AWS_REGION = "ap-south-1"
        AMI_ID = "ami-00bb6a80f01f03502"  // Replace with a valid AMI ID
        INSTANCE_TYPE = "t2.micro"
        KEY_NAME = "spkey1"
        SECURITY_GROUP = "guvi-project01-sg"  // Replace with your security group ID
        SUBNET_ID = "subnet-01764d41845dfeaa2"  // Replace with your subnet ID
    }

    stages {
        stage('Clone Repository') {
            steps {
                script {
                    echo "🚀 Triggered by GitHub Webhook: Branch = ${env.BRANCH_NAME}"
                    git branch: "${env.BRANCH_NAME}", url: 'https://github.com/psivasankaran1/Guvi-project1.git'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def IMAGE_NAME = "${DEV_REPO}:${IMAGE_TAG}"
                    if (env.BRANCH_NAME == "master") {
                        IMAGE_NAME = "${PROD_REPO}:${IMAGE_TAG}"
                    }
                    echo "🛠 Building Docker Image: $IMAGE_NAME"
                    sh "docker build -t $IMAGE_NAME ."
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                script {
                    def IMAGE_NAME = "${DEV_REPO}:${IMAGE_TAG}"
                    if (env.BRANCH_NAME == "master") {
                        IMAGE_NAME = "${PROD_REPO}:${IMAGE_TAG}"
                    }

                    withDockerRegistry([credentialsId: 'docker-hub-credentials', url: '']) {
                        echo "📤 Pushing Docker Image: $IMAGE_NAME"
                        sh "docker push $IMAGE_NAME"
                    }
                }
            }
        }

        // Only deploy if on master branch
        stage('Deploy to AWS') {
            when {
                branch 'master'
            }
            steps {
                script {
                    echo "🚀 Deploying to AWS (only for master branch)..."

                    stage('Create EC2 Instance') {
                        script {
                            echo "🖥 Creating EC2 instance..."
                            sh """
                                INSTANCE_ID=\$(aws ec2 run-instances \
                                    --image-id $AMI_ID \
                                    --instance-type $INSTANCE_TYPE \
                                    --key-name $KEY_NAME \
                                    --security-group-ids $SECURITY_GROUP \
                                    --subnet-id $SUBNET_ID \
                                    --count 1 \
                                    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=jenkins-deployed-instance}]' \
                                    --query 'Instances[0].InstanceId' --output text)
                                echo \$INSTANCE_ID > instance_id.txt
                            """
                        }
                    }

                    stage('Get EC2 Public IP') {
                        script {
                            def INSTANCE_ID = sh(script: "cat instance_id.txt", returnStdout: true).trim()
                            sh """
                                PUBLIC_IP=\$(aws ec2 describe-instances \
                                    --instance-ids $INSTANCE_ID \
                                    --query 'Reservations[0].Instances[0].PublicIpAddress' \
                                    --output text)
                                echo \$PUBLIC_IP > public_ip.txt
                            """
                        }
                    }

                    stage('Deploy Application to EC2') {
                        script {
                            def PUBLIC_IP = sh(script: "cat public_ip.txt", returnStdout: true).trim()
                            def IMAGE_NAME = "${PROD_REPO}:${IMAGE_TAG}"

                            echo "🚀 Deploying Docker container to EC2 instance..."
                            sh """
                                ssh -o StrictHostKeyChecking=no ec2-user@\$PUBLIC_IP <<EOF
                                    docker pull $IMAGE_NAME
                                    docker stop devops-app || true
                                    docker rm devops-app || true
                                    docker run -d --name devops-app -p 80:80 $IMAGE_NAME
                                EOF
                            """
                        }
                    }
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
