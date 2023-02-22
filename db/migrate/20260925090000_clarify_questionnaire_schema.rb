# The original schema used `questions.question_id` for the questionnaire's own
# string id ("q1") while `answers.question_id` was the bigint foreign key, so
# the same name meant two different things and the controller params inherited
# the ambiguity. This renames them apart, stores answer types as the labels the
# source actually uses instead of a fixed yes/no enum, and adds the uniqueness
# and lookup indexes the import and the per-question lookup rely on.
class ClarifyQuestionnaireSchema < ActiveRecord::Migration[7.0]
  ANSWER_TYPES = { 0 => "yes", 1 => "no" }.freeze

  def up
    rename_column :questions, :question_id, :external_id
    rename_column :answers, :next_question_id, :next_question_external_id
    rename_column :conclusions, :conclusion, :name

    add_column :answers, :answer_label, :string
    ANSWER_TYPES.each do |value, label|
      execute "UPDATE answers SET answer_label = #{connection.quote(label)} WHERE answer_type = #{value}"
    end
    remove_column :answers, :answer_type
    rename_column :answers, :answer_label, :answer_type

    change_column_null :questions, :external_id, false
    change_column_null :questions, :statement, false
    change_column_null :answers, :answer_type, false
    change_column_null :answers, :context, false
    change_column_null :conclusions, :name, false
    change_column_null :conclusions, :context, false

    add_index :questions, :external_id, unique: true
    add_index :answers, %i[question_id answer_type], unique: true
    add_index :answers, :next_question_external_id
    add_index :conclusions, :name, unique: true
  end

  def down
    remove_index :conclusions, :name
    remove_index :answers, :next_question_external_id
    remove_index :answers, %i[question_id answer_type]
    remove_index :questions, :external_id

    change_column_null :conclusions, :context, true
    change_column_null :conclusions, :name, true
    change_column_null :answers, :context, true
    change_column_null :answers, :answer_type, true
    change_column_null :questions, :statement, true
    change_column_null :questions, :external_id, true

    add_column :answers, :answer_enum, :integer
    ANSWER_TYPES.each do |value, label|
      execute "UPDATE answers SET answer_enum = #{value} WHERE answer_type = #{connection.quote(label)}"
    end
    remove_column :answers, :answer_type
    rename_column :answers, :answer_enum, :answer_type

    rename_column :conclusions, :name, :conclusion
    rename_column :answers, :next_question_external_id, :next_question_id
    rename_column :questions, :external_id, :question_id
  end
end
