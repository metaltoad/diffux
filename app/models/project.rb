# A Project represents a collection of Urls and Viewports that can have
# Snapshots taken on them, either by themselves or via Sweeps.
class Project < ActiveRecord::Base
  validates :name, presence: true

  attr_accessor :viewport_widths
  attr_accessor :url_addresses

  has_many :urls,      dependent: :destroy
  has_many :viewports, dependent: :destroy
  has_many :sweeps,    dependent: :destroy

  belongs_to :last_sweep, class_name: 'Sweep'

  after_validation :save_viewport_widths
  after_validation :save_url_addresses

  # @return [String]
  def viewport_widths
    @viewport_widths ||= viewports.pluck(:width).join("\n")
  end

  # @return [String]
  def url_addresses
    @url_addresses ||= urls.pluck(:address).join("\n")
  end

  # Updates the column cache for the last sweep.
  def refresh_last_sweep!
    self.last_sweep = sweeps.first
    save!
  end

  private

  # @param str [String]
  # @return [Array]
  def string_to_array(str)
    str.split(/\s+/).uniq.reject { |line| line.empty? }
  end

  def save_viewport_widths
    if viewport_widths
      old_widths = viewports.pluck(:width)
      new_widths = string_to_array(viewport_widths).map(&:to_i)

      (old_widths - new_widths).each do |width|
        viewports.where(width: width).destroy_all
      end

      (new_widths - old_widths).each do |width|
        viewports.new(width: width.to_i)
      end
    end
  end

  def save_url_addresses
    if url_addresses
      old_addresses = urls.pluck(:address)
      new_addresses = string_to_array(url_addresses)

      (old_addresses - new_addresses).each do |address|
        urls.where(address: address).destroy_all
      end

      (new_addresses - old_addresses).each do |address|
        urls.new(address: address)
      end
    end
  end
end
