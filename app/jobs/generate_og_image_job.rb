class GenerateOgImageJob < ApplicationJob
  queue_as :default

  def perform(highlight)
    html = ApplicationController.renderer.render(
      template: 'highlights/og_image',
      layout: false,
      assigns: { highlight: highlight }  # Pass @highlight
    )

    grover = Grover.new(html, format: 'png')
    image = grover.to_png  # Returns binary PNG data

    highlight.og_image.attach(
      io: StringIO.new(image),
      filename: "og_#{highlight.id}.png",
      content_type: 'image/png'
    )
  end
end