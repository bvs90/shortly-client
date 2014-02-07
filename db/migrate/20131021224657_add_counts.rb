class AddCounts < ActiveRecord::Migration
  def up
    add_column :links, :visits, :integer, :default => 0
  end

  def down
    remove_column :links, :visits
  end
end
