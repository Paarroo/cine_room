# app/helpers/videos_helper.rb
module VideosHelper
  def youtube_embed_url(url)
    return "" if url.blank?

    uri = URI.parse(url)

    video_id =
      if uri.host.include?("youtube.com")
        if uri.path.include?("/shorts/")
          uri.path.split("/").last
        else
          CGI.parse(uri.query.to_s)["v"]&.first
        end
      elsif uri.host.include?("youtu.be")
        uri.path.split("/").last
      end

    return "" unless video_id

    "https://www.youtube.com/embed/#{video_id}"
  rescue URI::InvalidURIError
    ""
  end
end
