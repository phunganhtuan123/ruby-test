pipeline {

   agent any

   environment {
    // Email configuration
    EMAIL_TO   = 'phunganhtuan123@gmail.com'
    EMAIL_BODY = "<p>Check console output at</p>"
    PATH = "$PATH:/usr/bin"
  }


  stages {
     stage('docker-compose') {
         steps {
            echo "PATH is: $PATH"
            sh "/usr/bin/docker-compose up --build -d"
         }
     }
  }

  post {
    success {
      emailext(
        attachmentsPattern: 'logs.zip',
        attachLog: true,
        compressLog: true,
        mimeType: 'text/html',
        to: env.EMAIL_TO,
        subject: "Success",
        body: env.EMAIL_BODY
      )
    }

    unstable {
      emailext(
        attachmentsPattern: 'logs.zip',
        attachLog: true,
        compressLog: true,
        mimeType: 'text/html',
        to: env.EMAIL_TO,
        subject: "Build unstabled in Jenkins",
        body: env.EMAIL_BODY
      )
    }

    failure {
      emailext(
        attachmentsPattern: 'logs.zip',
        attachLog: true,
        compressLog: true,
        mimeType: 'text/html',
        to: env.EMAIL_TO,
        subject: "Build failed in Jenkins",
        body: env.EMAIL_BODY
      )
    }
  }
}
