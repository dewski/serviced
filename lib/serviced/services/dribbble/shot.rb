module Serviced
  module Services
    class Shot
      include MongoMapper::EmbeddedDocument

      key :shot_id, Integer
      key :title
      key :url
      key :image_url
      key :image_teaser_url
      key :width, Integer, :default => 0
      key :height, Integer, :default => 0
      key :views_count, Integer, :default => 0
      key :comments_count, Integer, :default => 0

      def self.from(shot)
        new \
          :shot_id          => shot.id,
          :url              => shot.url,
          :image_url        => shot.image_url,
          :image_teaser_url => shot.image_teaser_url,
          :width            => shot.width,
          :height           => shot.height,
          :views_count      => shot.views_count,
          :comments_count   => shot.comments_count
      end

      def size
        "#{width}x#{height}"
      end
    end
  end
end
