require "test_helper"

module Quiz
  class GraphTest < ActiveSupport::TestCase
    setup { import_questionnaire! }

    test "loads the whole questionnaire in two queries" do
      queries = count_queries { Graph.current.context_paths }

      assert_equal 2, queries.size, "expected one query for questions and one for answers, got:\n#{queries.join("\n")}"
    end

    test "longest path is the worst case number of questions asked" do
      assert_equal 3, Graph.current.longest_path
    end

    test "find falls back to the root when no external id is given" do
      graph = Graph.current

      assert_equal graph.root, graph.find(nil)
      assert_equal graph.root, graph.find("")
      assert_equal "q3", graph.find("q3").external_id
      assert_nil graph.find("nope")
    end

    test "context paths enumerate every route to a leaf" do
      paths = Graph.current.context_paths

      assert_equal 6, paths.size
      assert_includes paths, [ "no tail", "nocturnal" ]
      assert_includes paths, [ "tail", "long tail (> 2in)", "diurnal" ]
    end

    test "dangling references are reported" do
      Question.find_by!(external_id: "q1").answers.first.update!(next_question_external_id: "q9")

      assert_equal [ "q9" ], Graph.current.dangling_references
    end

    test "a cyclic questionnaire is detected rather than looping forever" do
      Question.find_by!(external_id: "q3").answers.first.update!(next_question_external_id: "q1")

      assert_raises(Graph::CyclicQuestionnaire) { Graph.current.longest_path }
    end

    test "an empty questionnaire has no root and no paths" do
      Question.destroy_all
      graph = Graph.current

      assert_nil graph.root
      assert_equal 0, graph.longest_path
      assert_empty graph.context_paths
    end
  end
end
