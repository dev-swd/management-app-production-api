class AddNotProjectToProjects < ActiveRecord::Migration[6.1]
  def change
    add_column :projects, :not_project, :boolean, default: false, null: false
  end
end
