from flask import Flask, request
import os
import subprocess

app = Flask(__name__)

@app.route('/')
def home():
    return '''
    <h1>DevSecOps Demo Shop</h1>
    <p>Welcome to our online store!</p>
    <ul>
        <li><a href="/products">View Products</a></li>
        <li><a href="/health">Health Check</a></li>
    </ul>
    <p style="color:red;"><b>Warning: This app has intentional vulnerabilities for demo purposes.</b></p>
    '''

@app.route('/products')
def products():
    return '''
    <h2>Products</h2>
    <ul>
        <li>Laptop - $999</li>
        <li>Phone - $699</li>
        <li>Headphones - $199</li>
    </ul>
    '''

@app.route('/health')
def health():
    return {"status": "healthy", "app": "demo-shop", "version": "1.0.0"}

# ---------------------------------------------------------------
# VULNERABLE ENDPOINT — Simulates a real RCE vulnerability
# In real life this could be Log4Shell, Spring4Shell, or any RCE
# Attacker sends: /debug?cmd=whoami
# This is what Falco will detect
# ---------------------------------------------------------------
@app.route('/debug')
def debug():
    cmd = request.args.get('cmd', 'whoami')
    try:
        output = subprocess.check_output(cmd, shell=True, text=True, stderr=subprocess.STDOUT)
        return f"<pre>{output}</pre>"
    except Exception as e:
        return f"<pre>Error: {e}</pre>"

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port)
