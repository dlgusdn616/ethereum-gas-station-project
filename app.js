const Path = require('path');
const Hapi = require('hapi');
const Inert = require('inert');
const Web3 = require('web3');
const SerialPort = require('serialport');
const Readline = require('@serialport/parser-readline');
const port = new SerialPort('/dev/ttyACM0');
console.log('import libraries');

var web3 = new Web3(new Web3.providers.HttpProvider('http://127.0.0.1:7550'));
console.log('ethereum node connected');

var rpiAddr = 'Rpi Address';
// contract 인스턴스를 생성한다. new web3.eth.Contract(ABI, CA, { prarams... });
var myContract = new web3.eth.Contract(ABI, 'CA', {
    from: rpiAddr,
    gasPrice: '20000000000'
});
console.log('Got contract instance');
console.log(myContract.options);

//Reading from Arduino
const parser = port.pipe(new Readline({delimiter: '\r\n'}));

const server = new Hapi.Server({
    port: 3000,
    routes: {
        files: {
            relativeTo: Path.join(__dirname, 'public')
        }
    }
});

const provision = async () => {

    await server.register(Inert);

    server.route({
        method: 'GET',
        path: '/{param*}',
        handler: {
            directory: {
                path: '.',
                redirectToSlash: true,
                index: true,
            }
        }
    });

    server.route({
        method:'GET',
        path:'/usedgasamount/{value}',
        handler:function(request,h) {

            console.log("Is in the server.route");
            var cntSerial = 0;
            var extractedGasAmount = request.params.value;
            console.log(extractedGasAmount);//가스 나간 총 량 => 가스 나간양 + 전에 양 == 현재 양 공식 성립해야함


            parser.on('data', function(data) {

                var length = data.length;

                // 데이터가 시작되는 인덱스의 위치는 7, 설계하는 프로토콜에 따라 달라질 것이다.
                var sensor_value = data.slice(8, length);
                // 컨트랙트에 실제로 반영되는 값은 int값이기 때문에 파싱 과정을 진행해준다.
                var waterHeight = parseInt(sensor_value);

                var t0 = "0";


                if (cntSerial++ === 0) {
                    if(data[0] === t0) {
                            myContract.methods.checkGasTankAmount(extractedGasAmount, waterHeight).send({from: rpiAddr})
                            .then(console.log('call setString(' + extractedGasAmount + " " + waterHeight + ')'));
                    } else {
                        console.log('error');
                        console.log('data: ' + data);
                        console.log('data[0] ' + data[0]);
                    }
                }
            });
            return 0;
        }
     });
    await server.start();

    console.log('Server running at:', server.info.uri);
};

provision();