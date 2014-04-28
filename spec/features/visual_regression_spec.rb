require 'spec_helper'

describe 'Visual diffs', js: true, without_transactional_fixtures: true do
  before do
    Phantomjs.unstub(:run)
  end

  context 'Project#index' do
    let(:path)   { projects_path }

    [320, 1000].each do |width|
      context 'with no added project' do
        it 'has no visual regressions' do
          expect(path).to look_like_before(width: width)
        end
      end

      context 'with added projects' do
        before { create :project, name: 'Foo' }

        it 'has no visual regressions' do
          expect(path).to look_like_before(width: width)
        end
      end
    end
  end
end
