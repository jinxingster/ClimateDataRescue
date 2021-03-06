class Page < ActiveRecord::Base
  belongs_to :page_type
  has_many :transcriptions
  belongs_to :transcriber, class_name: "User"
  
  has_many :page_days

  #handles the image upload association
  has_attached_file :image,
                  styles: { 
                    thumb: ["64x64#", :jpg],
                    small: ["200x200>", :jpg],
                    medium: ["400x400>", :jpg],
                    large: ["600x600>", :jpg],
                    xlarge: ["1000x1000>", :jpg]
                  },
                  default_style: :medium,
                  url: "/system/:attachment/:style/:hash.:extension",
                  hash_secret: "SECRET"
  validates_attachment :image,
                     content_type: { content_type: ["image/jpg","image/jpeg", "image/png"] }
  before_save :extract_upload_dimensions
  # after_create :parse_filename
  
  def has_metadata?
    self.page_days.any? && self.page_days.count == ((self.end_date - self.start_date).to_i + 1)
  end
  
  def to_jq_upload
      {
        "name" => read_attribute(:image_file_name),
        "size" => image.size,
        "url" => image.url,
        "thumbnailUrl" => image.url(:thumb),
        "deleteUrl" => "/pages/#{self.id}",
        "deleteType" => "DELETE",
        "pageId" => "page-#{self.id}"
      }
  end
  
  after_create :parse_filename
  def parse_filename
    Page.transaction do
      # begin
        if self.image.present?
          filename = self.image_file_name
          components = filename.split("_")
          if components.count == 6
            self.accession_number = components[0]
            if components[1].length == 1 && components[2]
              ledger_type = components[1]
              volume = components[2]
              ledger = Ledger.find_by(volume: volume)
              unless ledger
                ledger = Ledger.create!(title: volume, ledger_type: ledger_type, volume: volume)
              end
            end
            self.start_date = Date.parse(components[3])
            self.end_date = Date.parse(components[4])
            
            self.title = components[3] + " to " + components[4]
            
            #TODO: Check that the heck this part of the filename means.
            if components[5] && components[5].length > 0
              page_type_num = components[5][0]
              page_type = PageType.find_by(number: page_type_num, ledger_id: ledger.id)
              if !page_type
                page_type = PageType.create!(number: page_type_num, ledger_type: ledger_type, ledger_id: ledger.id, title: (ledger_type + page_type_num + "-" + volume))
              end
              self.page_type_id = page_type.id
            end
          else
            raise "invalid filename"
          end
          
          self.save!
        end
      # rescue => e
        
      # end
      
    end
  end
  
  
  #sets the height and width attributes of the page to those of its attachment dimensions on update
  def extract_dimensions
    return unless self.image?
    #regex to select all parts of the filename preceding the end of the supported file types and forms
    reg = /(.+\.(jpg|JPG|jpeg|JPEG|png|PNG))/
    tempfile = self.image.url
    puts tempfile
    cleaned = reg.match(tempfile).to_s
    puts cleaned
    full_path = Rails.root.to_s + "/public" + cleaned
    puts full_path
    unless tempfile.nil?
      geometry = Paperclip::Geometry.from_file(full_path)
      self.width = geometry.width.to_i
      self.height = geometry.height.to_i
      self.save
    end
  end
  #sets the height and width attributes of the page to those of its attachment dimensions on create
  def extract_upload_dimensions
    return unless image?
    
    tempfile = image.queued_for_write[:original]
    
    unless tempfile.nil?
      geometry = Paperclip::Geometry.from_file(tempfile)
      self.width = geometry.width.to_i
      self.height = geometry.height.to_i
      # self.save
    end
  end
  #sets a scope for all transcribable pages to be those that are not done
  scope :transcribeable, -> { joins(:page_type).where(done: false, transcriber_id: nil, page_types: {number: 1}) }

  
  #constant that determines the # of transcriptions an page must have to be marked done
  CLASSIFICATION_COUNT = 5

  # def classification_limit
    # 5
  # end

  
  #on new transcription creation, increment the classification count of its associated page
  def increment_classification_count
    self.classification_count += 1
    if self.classification_count == CLASSIFICATION_COUNT
      self.done = true
    end
    self.save
  end

end
