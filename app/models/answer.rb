class Answer < ActiveRecord::Base
  belongs_to(:questioning)
  belongs_to(:option)
  belongs_to(:response)
  has_many(:choices)
  
  validates(:value, :numericality => true, :if => Proc.new{|a| a.numeric?})
  validate(:required)
  
  def self.new_from_str(params)
    str = params.delete(:str)
    ans = new(params)
    # set the attributes based on the question type
    case ans.question_type_name
    when "select_one"
      ans.option_id = str.to_i
    when "select_multiple"
      str.split(" ").each{|oid| ans.choices.build(:option_id => oid.to_i)}
    else
      ans.value = str
    end
    ans
  end

  def choice_for(option)
    choice_hash[option]
  end
    
  def choice_hash(options = {})
    if !@choice_hash || options[:rebuild]
      @choice_hash = {}; choices.each{|c| @choice_hash[c.option] = c}
    end
    @choice_hash
  end
  
  def all_choices
    # for each option, if we have a matching choice, return it and set it's fake bit to true
    # otherwise create one and set its fake bit to false
    options.collect do |o|
      if c = choice_for(o)
        c.checked = true
      else
        c = choices.new(:option_id => o.id, :checked => false)
      end
      c
    end
  end
  
  def all_choices=(params)
    # create a bunch of temp objects, discarding any unchecked choices
    submitted = params.values.collect{|p| p[:checked] == '1' ? Choice.new(p) : nil}.compact
    
    # copy new choices into old objects, creating or deleting if necessary
    choices.match(submitted, Proc.new{|c| c.option_id}) do |orig, subd|
      # if both exist, do nothing
      # if submitted is nil, destroy the original
      if subd.nil?
        choices.delete(orig)
      # if original is nil, add the new one to this response's array
      elsif orig.nil?
        choices << subd
      end
    end  
  end
  
  def question; questioning ? questioning.question : nil; end
  def rank; questioning.rank; end
  def required?; questioning.required?; end
  def question_name; question.name; end
  def question_hint; question.hint; end
  def question_type_name; question.type.name; end
  def can_have_choices?; question_type_name == "select_multiple"; end
  def numeric?; question_type_name == "numeric"; end
  def options; question.options; end
  def select_options; question.select_options; end
  
  private
    def required
      errors.add(:base, "This question is required") if required? && value.nil? && option_id.nil? && choices.empty?
    end
end
