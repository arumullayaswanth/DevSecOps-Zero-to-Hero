
# Step 1 — Open the Snyk website

Open this link in your browser:

```
https://app.snyk.io
```

Login using:

* GitHub (recommended)
* Google
* Email

You will enter the **Snyk dashboard.

---

# Step 2 — Open your profile menu

Look at the **top right corner** of the page.

You will see your **username or profile icon**.

Click on it.

A dropdown menu will open.

---

# Step 3 — Click **Account Settings**

From the dropdown menu click:

```
Account Settings
```

⚠️ Important:
Do **NOT stay in Organization Settings** 
You must open **Account Settings**.

---

# Step 4 — Open **General**

Inside **Account Settings**, click:

```
General
```

Now scroll down the page.

---

# Step 5 — Find **Auth Token**

Scroll until you see a section called:

```
Auth Token
```

It will show a long string like this:

```
8d92f3d1-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

Click the **Copy** button.

This is your **SNYK_TOKEN**.

---

# Step 6 — Install Snyk on your EC2 server

Login to your EC2 instance.

Run:

```bash
npm install -g snyk
```

Verify installation:

```bash
snyk --version
```

---

# Step 7 — Authenticate using the token (Optional)

Now run this command on EC2:

```bash
snyk auth YOUR_TOKEN
```

Example:

```bash
snyk auth 8d92f3d1-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

If successful you will see:

```
Your account has been authenticated.
```

---

# Step 8 — Add the token in Jenkins

Open Jenkins:

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

Fill the fields:

| Field       | Value                 |
| ----------- | --------------------- |
| Kind        | Secret Text           |
| Secret      | paste your Snyk token |
| ID          | snyk-token            |
| Description | snyk token            |

Click **Create**.

---

# Step 9 — Jenkins uses the token

Your pipeline stage already uses the token:

```groovy
withCredentials([string(credentialsId: 'snyk-token', variable: 'SNYK_TOKEN')]) {
    sh 'snyk auth $SNYK_TOKEN'
    sh 'snyk test --severity-threshold=high'
}
```

So Jenkins will:

```
Read token from credentials
Authenticate with Snyk
Scan project dependencies
```

---
