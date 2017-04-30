Rails.application.routes.draw do
# For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  namespace :cmdb do
    get 'organizations' => 'organizations#index'
  end

  namespace :cmdb do
    get 'sites' => 'sites#index'
    get 'sites/update' => 'sites#update_from_cmdb'
    get "sites/:id" => "sites#show" #, :constraints => {:id => /[\w._\-]*/}
    get "sites/:id/dhcp_snooping" => "sites#show_dhcp_snooping"
    get "sites/:id/update_device" => "sites#update_from_devices", :constraints => {:id => /[\w._\-]*/}
    get "sites/:id/create_project_files" => "sites#create_project_files", :constraints => {:id => /[\w._\-]*/}
  end

  namespace :cmdb do
    get 'devices' => 'devices#index'
    get 'devices/update' => 'devices#update_from_cmdb'
    get "devices/:id" => "devices#show", :constraints => {:id => /[\w._\-]*/}
    get "devices/:id/configuration" => "devices#show_configuration", :constraints => {:id => /[\w._\-]*/}
    get "devices/:id/interfaces" => "devices#show_interfaces", :constraints => {:id => /[\w._\-]*/}
    get "devices/:id/cdp" => "devices#show_cdp", :constraints => {:id => /[\w._\-]*/}
    get "devices/:id/update_device" => "devices#update_from_device", :constraints => {:id => /[\w._\-]*/}
  end

  namespace :cmdb do
    get 'interfaces' => 'interfaces#index'
    get "interfaces/:id" => "interfaces#show", :constraints => {:id => /[\w._\-]*/}
  end

  namespace :cmdb do
    get 'lines' => 'lines#index'
    get "lines/:id" => "lines#show", :constraints => {:id => /[\w._\-]*/}
  end

  namespace :cmdb do
    get 'subnets' => 'subnets#index'
    get "subnets/:id" => "subnets#show", :constraints => {:id => /[\w._\-]*/}
  end

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
