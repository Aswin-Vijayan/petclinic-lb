pipeline {
    agent {
        node {
            label 'agent-node'
        }
    }

    stages {
        stage('Pull Git Repo') {
            steps {
                git url: 'https://github.com/Aswin-Vijayan/petclinic-lb.git'
            }
        }
        
        stage('Lint Test') {
            steps {
                dir("/home/ubuntu/workspace/INFRA PIPELINES/petclinic-lb-asg"){
                sh 'terraform fmt --recursive'
                }
            }
        }
        
        stage('Provision lb-asg') {
            steps {
                dir("/home/ubuntu/workspace/INFRA PIPELINES/lb-asg/petclinic-lb-asg"){
                sh '''
                terraform init
                terraform apply -auto-approve
                '''
                }
            }
        }
    }
}
