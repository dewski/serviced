module Serviced
  module Services
    class Repository
      include MongoMapper::Document

      belongs_to :profile, :class_name => 'Serviced::Services::GitHub', :foreign_key => :git_hub_id

      key :repository_id, Integer
      key :name
      key :description
      key :url
      key :fork, Boolean, :default => false
      key :fork_count, Integer
      key :watchers_count, Integer
      key :open_issues_count, Integer
      key :pushed_at, DateTime
      timestamps!

      scope :popular, sort(:watchers_count.desc).limit(5)

      def self.from(repository)
        new \
          :repository_id      => repository.id,
          :name               => repository.name,
          :description        => repository.description,
          :url                => repository.html_url,
          :fork               => repository.fork?,
          :fork_count         => repository.forks,
          :watchers_count     => repository.watchers,
          :open_issues_count  => repository.open_issues,
          :pushed_at          => repository.pushed_at
      end

      def to_param
        url
      end

      def to_s
        name
      end
    end
  end
end
