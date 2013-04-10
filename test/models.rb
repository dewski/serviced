class TestModel
  include ActiveModel::Validations
  extend ActiveModel::Callbacks
  define_model_callbacks :create, :update, :destroy, :commit

  include Serviced::Base
end

class Gmail < TestModel
end

class Hotmail < TestModel
end
