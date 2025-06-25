Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # ActionCable WebSocket route
  mount ActionCable.server => "/cable"

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Bulk import routes (must come before resources to avoid conflicts)
  get "urls/bulk_import", to: "urls#bulk_import", as: :bulk_import_urls
  post "urls/process_bulk_import", to: "urls#process_bulk_import", as: :process_bulk_import_urls

  # Bulk analysis route (must come before resources to avoid conflicts)
  post "urls/bulk_analyze", to: "urls#bulk_analyze", as: :bulk_analyze_urls

  # Bulk delete route (must come before resources to avoid conflicts)
  delete "urls/delete_all", to: "urls#delete_all", as: :delete_all_urls

  # Export route (must come before resources to avoid conflicts)
  get "urls/export", to: "urls#export", as: :export_urls, defaults: { format: :csv }

  # URL management routes
  resources :urls do
    resources :sentiment_analyses, only: [ :create ]
  end

  # Defines the root path route ("/")
  root "urls#index"

  # Reports route
  get "reports", to: "reports#index", as: :reports
  get "reports/download_pdf", to: "reports#download_pdf", as: :download_reports_pdf, defaults: { format: :pdf }
end
