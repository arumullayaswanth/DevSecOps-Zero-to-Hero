

# Step 1 — Open the OpenWeather Website

Go to this website:

```
https://home.openweathermap.org/users/sign_up
```

This is the website of **OpenWeather**.

---

# Step 2 — Create an Account

Fill the form:

* **Username**
* **Email**
* **Password**

Check the box:

```
I agree to the terms
```

Click:

```
Create Account
```

---

# Step 3 — Verify Your Email

Open your email inbox.

You will receive an email from **OpenWeather**.

Click the **verification link**.

Your account is now activated.

---

# Step 4 — Login to OpenWeather

Open:

```
https://home.openweathermap.org/users/sign_in
```

Login using your:

* Email
* Password

---

# Step 5 — Open the API Keys Page

After login, open this page:

```
https://home.openweathermap.org/api_keys
```

You will see something like:

```
Key Name: default
API Key: xxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

Example:

```
9f4e6d7a3xxxxxxxxxxxxxxxxxxxxxxx
```

Copy this key.

⚠️ This is your **OpenWeather API key**.

---

# Step 6 — Add API Key in Jenkins

Open **Jenkins** in your browser:

```
http://EC2_PUBLIC_IP:8080
```

Go to:

```
Manage Jenkins
→ Credentials
→ Global
→ Add Credentials
```

Fill the fields like this:

| Field       | Value                          |
| ----------- | ------------------------------ |
| Kind        | Secret Text                    |
| Secret      | paste your OpenWeather API key |
| ID          | openweather-api-key            |
| Description | OpenWeather API key            |

Click:

```
Create
```

---

# Step 7 — Jenkins Uses the Key

Your pipeline already uses it here:

```groovy
withCredentials([string(credentialsId: 'openweather-api-key', variable: 'REACT_APP_OPENWEATHER_API_KEY')]) {
  sh 'npm run build'
}
```

What happens:

```
Jenkins
   ↓
Reads API key from credentials
   ↓
Passes it to React build
   ↓
React app calls OpenWeather API
```

---

# Step 8 — Test the API Key (Optional)

Open your browser and test the API.

Replace `YOUR_KEY`:

```
https://api.openweathermap.org/data/2.5/weather?q=London&appid=YOUR_KEY
```

If the key works you will see weather data in JSON.

---

# Final Result

Now your weather app will work like this:

```
User → React App → OpenWeather API → Weather Data → Screen
```

And your Jenkins pipeline will build the app using the API key securely.
