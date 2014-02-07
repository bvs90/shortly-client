class CreateClicks < ActiveRecord::Migration
  def up
    create_table :clicks do |t|
        t.integer :link_id
        t.timestamps
    end
  end

  def down
    drop_table :clicks
  end
end
