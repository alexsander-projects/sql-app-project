import React, { useEffect, useState } from 'react';
import './App.css';

function App() {
  const [products, setProducts] = useState([]);

  useEffect(() => {
    fetch('http://127.0.0.1:8000')
        .then(response => response.json())
        .then(data => setProducts(data));
  }, []);

  return (
      <div className="App">
        <h1>Products</h1>
        {products.map(product => (
            <div key={product.ProductID}>
              <h2>{product.ProductName}</h2>
              <p>{product.Quantity}</p>
            </div>
        ))}
      </div>
  );
}

export default App;