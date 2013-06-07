module Serviced
  module Services
    class Twitter
      include Model
    end
  end
end

class Email
  include ActiveModel::Validations
  extend ActiveModel::Callbacks
  define_model_callbacks :create, :update, :destroy, :commit

  include Serviced::Base
end

class Gmail < Email
end

class Hotmail < Email
end

class User
  include ActiveModel::Validations
  extend ActiveModel::Callbacks
  define_model_callbacks :create, :update, :destroy, :commit

  include Serviced::Base
end

class Candidate
  include ActiveModel::Validations
  extend ActiveModel::Callbacks
  define_model_callbacks :create, :update, :destroy, :commit

  include Serviced::Base

  def id
    1
  end
end
