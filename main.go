package main

import (
	"fmt"
	"log"
	"net/http"
	"time"
)

func handler(w http.ResponseWriter, r *http.Request) {
	currentTime := time.Now()
	timeStr := currentTime.Format("2006-01-02 15:04:05 MST")

	html := fmt.Sprintf(`
<!DOCTYPE html>
<html>
<head>
    <title>Current Date & Time</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            background: linear-gradient(135deg, #667eea 0%%, #764ba2 100%%);
            color: white;
        }
        .container {
            text-align: center;
            background: rgba(255, 255, 255, 0.1);
            padding: 40px;
            border-radius: 20px;
            backdrop-filter: blur(10px);
            box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
        }
        h1 {
            font-size: 3em;
            margin-bottom: 20px;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
        }
        .time {
            font-size: 2em;
            font-weight: bold;
            margin: 20px 0;
            padding: 20px;
            background: rgba(255, 255, 255, 0.2);
            border-radius: 10px;
            border: 1px solid rgba(255, 255, 255, 0.3);
        }
        .refresh {
            margin-top: 30px;
        }
        .refresh a {
            color: white;
            text-decoration: none;
            padding: 10px 20px;
            background: rgba(255, 255, 255, 0.2);
            border-radius: 5px;
            border: 1px solid rgba(255, 255, 255, 0.3);
            transition: background 0.3s;
        }
        .refresh a:hover {
            background: rgba(255, 255, 255, 0.3);
        }
    </style>
    <meta http-equiv="refresh" content="5">
</head>
<body>
    <div class="container">
        <h1> Current Date & Time</h1>
        <div class="time">%s</div>
        <div class="refresh">
            <a href="/">Refresh</a>
        </div>
    </div>
</body>
</html>`, timeStr)

	w.Header().Set("Content-Type", "text/html")
	fmt.Fprint(w, html)
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	fmt.Fprint(w, "OK")
}

func main() {
	http.HandleFunc("/", handler)
	http.HandleFunc("/health", healthHandler)

	port := ":8080"
	fmt.Printf("Server starting on port %s\n", port)
	fmt.Println("Visit http://localhost:8080 to see the current date and time")

	log.Fatal(http.ListenAndServe(port, nil))
}
