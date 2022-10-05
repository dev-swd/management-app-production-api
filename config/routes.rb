Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do

      # テスト用API
      resources :test, only: %i[index]

      # DEVISE認証用API
      mount_devise_token_auth_for 'User', at: 'auth', controllers: {
        registrations: 'api/v1/auth/registrations'
      }
      namespace :auth do
        resources :sessions, only: %i[index]
      end

      # 承認権限情報
      resources :approvalauths do
        member do
          get :index_by_division
          get :index_by_dep_direct
        end
      end

      # 監査情報
      resources :audits do
        collection do
          get :index_by_project
        end
      end

      # プロジェクト計画書変更履歴
      resources :changelogs do
        member do
          get :index_by_project
        end
      end

      # 日報
      resources :dailyreports do
        member do
          patch :status_update
        end
        collection do
          get :index_by_emp
          patch :approval_update
          patch :approval_cancel
        end
      end
      
      # 事業部情報
      resources :departments
      
      # 課情報
      resources :divisions do
        member do
          get :index_by_department
          get :index_by_approval
          get :show_by_depdummy
        end
        collection do
          get :index_with_authcnt
        end
      end

      # 社員情報
      resources :employees do
        member do
          get :show_by_devise
          get :index_by_approval
          get :index_by_div
          get :index_by_dep_direct
          get :show_with_devise
          patch :update_password_with_currentpassword
          patch :update_password_without_currentpassword
          get :show_no_project
        end
        collection do
          get :index_by_not_assign
          get :index_devise
          post :create_with_password
        end
      end

      # EVM情報
      resources :evms do
        collection do
          get :index_by_conditional
        end
      end
      
      # プロジェクトメンバー
      resources :members

      # 工程情報
      resources :phases do
        member do
          get :index_by_project
          get :index_plan_and_actual
        end
      end

      # 進捗報告書
      resources :progressreports do
        member do
          get :index_by_project
          patch :create_report
        end
      end

      # プロジェクト情報
      resources :projects do
        member do
          get :index_by_member_running
          get :index_todo
          get :show_no_project
          patch :update_no_project
        end
        collection do
          get :index_pl
          get :index_by_member
          get :index_by_conditional
          post :create_no_project
          get :index_audit_todo
        end
      end

      # 品質目標
      resources :qualitygoals

      # 完了報告書
      resources :reports

      # リスク
      resources :risks

      # タスク情報
      resources :tasks do
        member do
          get :index_by_phase
          get :index_by_project
          patch :update_for_planned
          patch :update_for_actualdate
          get :index_todo
          get :index_by_phase_without_outsourcing
        end
        collection do
          get :index_plan_and_actual
        end
      end

      # 作業日報
      resources :workreports do
        member do
          get :index_by_daily
        end
      end

    end
  end
end
