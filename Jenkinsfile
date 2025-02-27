pipeline {
    agent any

    environment {
        DEV_REPO = "prabakaran90/devops-app-dev"
        PROD_REPO = "prabakaran90/devops-app-prod"
        IMAGE_TAG = "latest"

        // AWS Configuration
        AWS_REGION = "ap-south-1"
        AMI_ID = "ami-00bb6a80f01f03502"
        INSTANCE_TYPE = "t2.micro"
        KEY_NAME = "spkey1"
        SECURITY_GROUP = "sg-051078e33cc22ee9a"
        SUBNET_ID = "subnet-01764d41845dfeaa2"
    }

    stages {
        stage('Clone Repository') {
            steps {
                script {
                    def BRANCH = env.BRANCH_NAME ?: env.GIT_BRANCH?.replace('origin/', '') ?: 'dev'
                    echo "🚀 Cloning repository: Branch = ${BRANCH}"
                    git credentialsId: 'github-credentials', branch: BRANCH, url: 'https://github.com/psivasankaran1/devops-deployment.git'
                    env.CURRENT_BRANCH = BRANCH
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def IMAGE_NAME = "${DEV_REPO}:${IMAGE_TAG}"
                    if (env.CURRENT_BRANCH == "master") {
                        IMAGE_NAME = "${PROD_REPO}:${IMAGE_TAG}"
                    }
                    echo "🛠 Building Docker Image: ${IMAGE_NAME}"
                    sh "docker build -t ${IMAGE_NAME} ."
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                script {
                    def IMAGE_NAME = "${DEV_REPO}:${IMAGE_TAG}"
                    if (env.CURRENT_BRANCH == "master") {
                        IMAGE_NAME = "${PROD_REPO}:${IMAGE_TAG}"
                    }

                    withDockerRegistry([credentialsId: 'docker-hub-credentials', url: 'https://index.docker.io/v1/']) {
                        echo "📤 Pushing Docker Image: ${IMAGE_NAME}"
                        sh "docker push ${IMAGE_NAME}"
                    }
                }
            }
        }

        stage('Deploy to AWS') {
            when {
                expression { env.CURRENT_BRANCH == 'master' }
            }
            steps {
                script {
                    echo "🚀 Deploying to AWS (only for master branch)..."

                    // AWS credentials setup
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-access-key-id']]) {
                        echo "🖥 Creating EC2 instance..."
                        sh """
                            INSTANCE_ID=\$(aws ec2 run-instances \
                                --image-id ${AMI_ID} \
                                --instance-type ${INSTANCE_TYPE} \
                                --key-name ${KEY_NAME} \
                                --security-group-ids ${SECURITY_GROUP} \
                                --subnet-id ${SUBNET_ID} \
                                --count 1 \
                                --user-data file://deploy.sh \
                                --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=jenkins-deployed-instance}]' \
                                --query 'Instances[0].InstanceId' --output text)
                            echo "\$INSTANCE_ID" > instance_id.txt
                        """

                        echo "🕒 Waiting for EC2 instance to be running..."
                        sh "aws ec2 wait instance-running --instance-ids \$(cat instance_id.txt)"

                        echo "🌐 Getting EC2 Public IP..."
                        retry(3) {
                            sh """
                                PUBLIC_IP=\$(aws ec2 describe-instances \
                                    --instance-ids \$(cat instance_id.txt) \
                                    --query 'Reservations[*].Instances[*].PublicIpAddress' \
                                    --output text 2> aws_error.log)
                                echo "Public IP from AWS CLI: \$PUBLIC_IP"
                                echo "\$PUBLIC_IP" > public_ip.txt
                                cat aws_error.log
                            """
                        }

                        def PUBLIC_IP = sh(script: "cat public_ip.txt", returnStdout: true).trim()
                        echo "Public IP: ${PUBLIC_IP}"
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
