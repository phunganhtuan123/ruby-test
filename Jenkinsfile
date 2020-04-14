pipeline {
  agent {
    docker {
      image 'ruby:2.6.3'
      args '-v $HOME/bundle_cache/Backend/bundle:/usr/local/bundle'
    }
  }

  environment {
    // Email configuration
    EMAIL_TO   = 'phunganhtuan123@gmail.com'
    EMAIL_BODY = "<p>Check console output at</p>"
  }

  stages {
    stage('Requirements') {
      steps {
        sh 'apt-get update'
        sh 'apt-get install -y default-libmysqlclient-dev'
        sh 'apt-get install -y libgd-dev'
        sh 'apt-get install -y default-mysql-client'
        sh 'apt-get install -y zip'
        sh 'gem install bundler -v 2.0.2'
        sh 'bundle install --jobs 4 --retry 3'
        sh 'cp config/database.yml.template config/database.yml'
      }
    }

    stage('Unit test') {
      steps {
        // Just for the first time
        // sh 'bundle exec rake db:setup_test'

        // And for another time
        sh 'RACK_ENV=test bundle exec rake db:migrate'
        sh 'RACK_ENV=test bundle exec rake db:seed'

        sh 'rm -rf logs/*'
        sh 'bundle exec rspec'
      }
    }
  }

  post {
    always {
      sh 'zip -r logs.zip logs/*'

      step([
        $class: 'RcovPublisher',
        reportDir: 'coverage/rcov',
        targets: [
          [
            $class: 'hudson.plugins.rubyMetrics.rcov.model.MetricTarget',
            metric: 'TOTAL_COVERAGE',
            healthy: 15,
            unhealthy: 13,
            unstable: 10
          ],
          [
            $class: 'hudson.plugins.rubyMetrics.rcov.model.MetricTarget',
            metric: 'CODE_COVERAGE',
            healthy: 15,
            unhealthy: 13,
            unstable: 10
          ]
        ]
      ])
    }

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
