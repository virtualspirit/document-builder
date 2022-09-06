Rails.application.routes.draw do
  mount Document::Engine => "/document"
end
