pipeline {
    agent {
        node {
            label 'agent-node'
        }
    }

    stages {
        stage('Lint Test') {
            steps {
                dir("/home/ubuntu/workspace/INFRA PIPELINES/lb-asg"){
                sh 'terraform fmt --recursive'
                }
            }
        }
        
        stage('Provision lb-asg') {
            steps {
                dir("/home/ubuntu/workspace/INFRA PIPELINES/lb-asg/petclinic-lb-asg"){
                sh '''
                terraform init
                terraform destroy -auto-approve
                '''
                }
            }
        }
    }
}
