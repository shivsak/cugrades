json.extract! instructor, :id, :name, :course, :range, :created_at, :updated_at
json.url instructor_url(instructor, format: :json)