class AddPrefilledToChamps < ActiveRecord::Migration[6.1]
  def change
    add_column :champs, :prefilled, :boolean, default: false
  end
end
