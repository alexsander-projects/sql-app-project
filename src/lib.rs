use anyhow::Ok;
use async_std::net::TcpStream;
use once_cell::sync::Lazy;
use tiberius::{Client, Config};
use std::env;


static CONN_STR_PORT: Lazy<String> = Lazy::new(|| {
    env::var("TIBERIUS_TEST_CONNECTION_STRING").unwrap_or_else(|_| {
        "<CONNECTION_STRING>".to_owned()
    })
});

/// Connect to an SQL Server instance using the hostname and port number.
async fn connect_through_port() -> anyhow::Result<()> {

    let config = Config::from_ado_string(&CONN_STR_PORT)?;

    // Create a `TCPStream` from the `async-std` library with
    // a address that contains the hostname/IP and port number.
    let tcp = TcpStream::connect(config.get_addr()).await?;

    tcp.set_nodelay(true)?;

    // Connect to SQL Server
    let client = Client::connect(config, tcp).await?;
    println!("Successfully connected to server.");

    client.close().await?;

    Ok(())
}