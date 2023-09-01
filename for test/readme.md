brew install terragrunt
brew install httpie

export MODULE_VERSION=1.0.0
export ENVIRONMENT=prod
terragrunt apply
terragrunt plan -var-file "test.txt"


####
./httpie_v2.sh urls.txt
./httpie_v2.sh urls.txt waf-acme-lb-689292295.us-west-2.elb.amazonaws.com



fetch('http://waf-acme-lb-689292295.us-west-2.elb.amazonaws.com/static/123123', {
    headers: {
        'X-API-Key': 'foobarbaz'
    }
})
.then(response => response.text()) // Исправлено на response.text()
.then(data => console.log(data))
.catch(error => console.error('Ошибка:', error));
