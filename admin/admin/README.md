User Registration → Free Access → Subscription Purchase → Premium Access

API Routes

GET
http://localhost:8088/api/general-setting
http://localhost:8088/api/admob-setting
http://localhost:8088/api/facebook-ads-setting
http://localhost:8088/api/contact-setting
http://localhost:8088/api/popup-setting


POST
http://localhost:8088/api/server-connect
Payload: {server_id: number, protocol: string}

http://localhost:8088/api/server-disconnect
payload: {server_id: number, protocol: string}
