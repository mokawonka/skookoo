# Rack middleware to allow /extension_modal to be embedded in iframes
# (Chrome extension needs this - Rails defaults to X-Frame-Options: SAMEORIGIN)
class ExtensionFrameMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, body = @app.call(env)

    path = (env["PATH_INFO"] || env["REQUEST_PATH"] || "").split("?").first
    if path == "/extension_modal"
      headers.delete("X-Frame-Options")
      headers["Content-Security-Policy"] = "frame-ancestors *"
    end

    [status, headers, body]
  end
end
