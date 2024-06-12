use async_std::net::TcpStream;
use dotenv::dotenv;
use rocket::{get, routes, Rocket, State, catch, catchers};
use rocket::serde::json::Json;
use std::env;
use tiberius::{Client, Config};
use rocket_cors::{AllowedOrigins, CorsOptions};


#[derive(serde::Serialize)]
struct Products {
    ProductID: i32,
    ProductName: String,
    Quantity: String,
}

#[get("/")]
async fn get_products() -> Json<Vec<Products>> {
    let connection_string = env::var("CONNECTION_STRING").expect("CONNECTION_STRING must be set");

    let config = Config::from_ado_string(&connection_string).unwrap();
    let tcp = TcpStream::connect(config.get_addr()).await.unwrap();
    tcp.set_nodelay(true).unwrap();

    let mut client = Client::connect(config, tcp).await.unwrap();

    let mut products = Vec::<Products>::new();

    let rows = client
        .query("SELECT ProductID, ProductName, Quantity FROM Products", &[&1i32])
        .await.unwrap()
        .into_first_result()
        .await.unwrap();

    for row in rows {
        let ProductID: i32 = row.get("ProductID").unwrap();
        let ProductName: &str = row.get("ProductName").unwrap();
        let Quantity: i32 = row.get("Quantity").unwrap();

        products.push(Products {
            ProductID,
            ProductName: ProductName.to_string(),
            Quantity: Quantity.to_string(),
        });
    }

    Json(products)
}

#[catch(404)]
fn not_found() -> &'static str {
    "The requested resource could not be found."
}

#[rocket::main]
async fn main() {
    dotenv().ok();

    let allowed_origins = AllowedOrigins::all();

    let cors = CorsOptions::default()
        .allowed_origins(allowed_origins)
        .allow_credentials(true)
        .to_cors()
        .unwrap();

    rocket::build()
        .mount("/", routes![get_products])
        .register("/", catchers![not_found])
        .attach(cors)
        .launch()
        .await.unwrap();
}