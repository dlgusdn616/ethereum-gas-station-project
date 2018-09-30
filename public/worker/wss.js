(function(){
	let socket = null;

	self.addEventListener('message', function(e) {
		
		console.log("[wss worker.js]에서 core.js로부터 메시지를 수신하였습니다.", e.data);

		let	data = e.data,
			router = data.r,
			message = data.m,
			returnMessage = null;

		switch( router ) {

			case "init": socket.init(message); break;
			case "API": socket.API( message ); break;
			case "reConnect": socket.reConnect(data.room); break;
		}
	});

	function Socket(){

		console.log('socket 실행됨?');

		const URL = "ws://127.0.0.1:3000?";

		let Ws = null,
			token = null,
			initSw = 0;

		return({ init: init,
				 reConnect: reConnect,
				 API: API  });

		function init(rM){

			console.log('wss init start', rM);

			let query = {connect: "init", message: rM.m};

			query = JSON.stringify( query );

			Ws = new WebSocket( URL + query );

			console.log('[wss worker.js]에서 socket이 start되었습니다. : ' + query);

			Ws.onopen 	= onOpen;
			Ws.onclose 	= onClose;
			Ws.onerror 	= onError;
			Ws.onmessage = onMessage;
		}

		function reConnect(m){
			
			let query = {};

			delete Ws.onopen;
			delete Ws.onclose;
			delete Ws.onerror;
			delete Ws.onmessage;

			if(initSw)
				query = { connect: "reConnect", room: m, token: token };
			else
				query = { connect: "init", token: token };
			
			query = JSON.stringify( query );

			Ws = new WebSocket( URL + query );

			Ws.onopen 	= onOpen;
			Ws.onclose 	= onClose;
			Ws.onerror 	= onError;
			Ws.onmessage = onMessage;
		}

		// 서버측으로 메시지 전송
		function API(m){ 

			let parameters = JSON.stringify(m);
		
			Ws.send( parameters ); 
		}


		// 서버측에서 메시지 수신
		function onMessage(m){ 

			let msg = JSON.parse( m.data );
			
			console.log("서버로부터 메시지를 수신하였습니다.", msg);

			self.postMessage(msg); 
		}


		function onClose(err){

			let closeTimer = 0;

			closeTimer = setTimeout(function(){

				if(initSw){
					// 최초 접속시 에러가 아니라 중간에 접속 종료시 현재 룸 상태를 파악해야 한다.
					self.postMessage( {router:[0, "reConnect"]} );
				}else{
					// 초기화가 진해되지 않았으면 재접속
					reConnect();
				}
			},3000);
		}

		function disconnect(){ Ws.close(); }
		function onOpen(){ initSw = 1; }
		function onError() { console.log('접속 오류 리셋합니다.'); }
	}

	socket = new Socket();
})();