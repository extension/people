class AddDownloads < ActiveRecord::Migration
  def change

    create_table "downloads", :force => true do |t|
      t.string   "label"
      t.string   "display_label"
      t.string   "filetype"
      t.string   "objectclass"
      t.string   "objectmethod"
      t.boolean  "method_writes_file", :default => false             
      t.integer  "period", :default => 0
      t.boolean  "in_progress", :default => false
      t.boolean  "is_private", :default => false
      t.datetime "last_generated_at"
      t.float    "last_runtime"
      t.integer  "last_filesize"
      t.timestamps
    end

    add_index "downloads", ["label","period"], :name => "download_ndx"

    # create initial downloads
    Download.reset_column_information
    Download.create(label: 'aae_evaluation', 
                    display_label: 'Ask an Expert Evaluation',
                    objectclass: 'AaeQuestion', 
                    objectmethod: 'evaluation_data_csv', 
                    filetype: 'csv', 
                    period: Download::WEEKLY, 
                    is_private: true)

    Download.create(label: 'aae_questions',
                    display_label: 'Ask an Expert Question Data',
                    objectclass: 'AaeQuestion', 
                    objectmethod: 'questions_csv', 
                    filetype: 'csv', 
                    period: Download::WEEKLY, 
                    method_writes_file: true)
  end

end
