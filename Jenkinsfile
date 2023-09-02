pipeline {
  agent {label 'docker-agent'}
  stages {
    stage('clean'){
      steps {
        //clean the workspace and build code
        sh 'dotnet clean /home/ubuntu/workspace/jenkinsjob/sqlapp'
      }
    }
      stage('restore, publish and deploy to azure'){
        steps{
          //restore, publish and zip package
          sh '''
              dotnet restore /home/ubuntu/workspace/jenkinsjob/sqlapp --packages .nuget/ --runtime win-x64
              dotnet publish /home/ubuntu/workspace/jenkinsjob/sqlapp --no-restore --runtime win-x64 --no-self-contained -o ./tmp/publish
              cd tmp/publish
              zip -r publish.zip .
              '''
        }
      }
    }
    post {
        always {
          //archive artifacts to be download on azure
            archiveArtifacts artifacts: 'tmp/publish/publish.zip'
        }
    }
}
