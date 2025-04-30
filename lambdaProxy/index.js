/*
* SANS SEC540 API GW Lambda Proxy.
*
*
* Derived from the following projects:
* - https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-create-api-as-simple-proxy-for-lambda.html
*/

var http = require('http');

exports.handler = function (event, context, callback) {
    //request vars
    var requestPath = event.path
    var requestMethod = event.httpMethod
    var requestBody = event.body != null ? JSON.stringify(JSON.parse(event.body)) : ''
    console.log('Received event: ' + requestMethod + ' ' + requestPath);

    //http request options
    var options = {
        host: 'api.aws.main.d3m9wu6rhd9z99.amplifyapp.com',
        port: 8080,
        path: requestPath,
        method: requestMethod,
        headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
        },
        body: requestBody
    };

    //http request object w/ options and callback
    var request = http.request(options, function (res) {
        var responseBody = '';
        res.on('data', function (chunk) {
            responseBody += chunk; //collect response data
        });
        res.on('end', function () {
            var statusCode = res.statusCode.toString();
            console.log('API responded with status code ' + statusCode);
            let response = {
                statusCode: statusCode,
                headers: {},
                body: JSON.stringify(JSON.parse(responseBody))
            };
            callback(null, response);
        });
    }).on('error', function (e) {
        console.log('Error invoking API: ' + e.message);
        let response = {
            statusCode: 500,
            headers: {},
            body: JSON.stringify({ "message": "Error invoking API: " + e.message })
        };
        callback(null, response);
    });

    //send request
    request.write(requestBody);
    request.end();
};