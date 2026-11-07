# Oktan activation

```lua
getgenv().Key = "YOUR_KEY"
loadstring(game:HttpGet("https://raw.githubusercontent.com/barmunddd/Oktan/main/loader.luau"))()
```

The loader sends the entered key over HTTPS to the owner's verification service. Only an HTTP 200 response with JSON `valid: true` allows it to fetch and start the pinned client revision. Missing, rejected or expired keys, malformed responses and request failures stop the loader. Executor HTTP request support is required.

The key database and generator are not published here. Keys created locally must also exist in the deployed server database. Revocation/expiry is checked on startup, not continuously during an existing session.

This is a conventional startup gate, not source protection: the client source is public and can be loaded separately or modified. The loader cannot prevent executor injection. It only controls its own client download/start. Mock tests and Luau compilation passed; actual executor/network compatibility still needs testing.
