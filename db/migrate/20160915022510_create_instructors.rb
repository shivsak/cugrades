class CreateInstructors < ActiveRecord::Migration
  def change
    create_table :instructors do |t|
      t.string :name
      t.string :course
      t.integer :range

      t.timestamps null: false
    end
  end
end
