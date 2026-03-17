Adding a new server/tunnel:

- Add a tunnel on Cloudflare: https://one.dash.cloudflare.com/bb1f6ee516720b415e40bddbcef937ba/networks/connectors
- Click one of them and get the eyJ token
- 'Next' and create a published application. Use e.g. servers | goodways.org, and send over http to localhost:80

On servers.goodways.org
- Add a new resource (cloudflared) to the Cloudflared project
- Update the env variable and deploy it

- Go to the new server in 'servers' & check the proxy is running
