module Brestprog
  class RegionalsGenerator < Jekyll::Generator
    def generate(site)
      site.data['dynamic'] ||= {}
      site.data['dynamic']['participants'] = ParticipantsData.new(site)
      site.data['dynamic']['schools'] = SchoolsData.new(site)

      site.data['contests']['regionals'].each do |year, results|
        results.each_key do |region|
          site.pages << RegionalsResultsPage.new(site, site.source, region, year)
        end
      end
    end
  end

  module EntityCollection
    def all
      unless defined?(@all)
        @all = @site.data[@collection].each_with_object({}) do |(_, participant), acc|
          acc[participant['id']] = participant
        end
      end
      @all
    end

    def [](id)
      all[id]
    end
  end

  class ParticipantsData
    include EntityCollection

    def initialize(site)
      @site = site
      @collection = 'participants'
    end
  end

  class SchoolsData
    include EntityCollection

    def initialize(site)
      @site = site
      @collection = 'schools'
    end
  end

  module DynamicDataPage
    def participants
      @site.data['dynamic']['participants']
    end

    def schools
      @site.data['dynamic']['schools']
    end
  end

  class RegionalsResultsPage < Jekyll::Page
    include DynamicDataPage

    REGION_CONTEST_NAMES = {
      'brest' => 'Брест, областная олимпиада',
      'viciebsk' => 'Витебск, областная олимпиада',
      'homiel' => 'Гомель, областная олимпиада',
      'hrodna' => 'Гродно, областная олимпиада',
      'minsk-voblasc' => 'Минская областная олимпиада',
      'mahiliou' => 'Могилёв, областная олимпиада',
      'minsk-horad' => 'г. Минск, городская олимпиада',
      'licej-bdu' => 'Лицей БГУ, третий этап республиканской олимпиады',
    }

    INCOMPLETE_RESULTS = [
      ['viciebsk', 2018]
    ]

    def initialize(site, base, region, year)
      @site = site
      @base = base
      @dir = "results/#{region}"
      @name = "#{year}.html"

      results = self.collect_results(site, region, year)
      has_task_breakup = results[0].has_key? 'tasks'

      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), 'results_page.html')
      self.data['wide'] = has_task_breakup
      self.data['title'] = "#{REGION_CONTEST_NAMES[region]}, #{year}"
      self.data['results'] = results
      self.data['has_task_breakup'] = has_task_breakup
      self.data['incomplete'] = INCOMPLETE_RESULTS.include? [region, year.to_i]
    end

    def collect_results(site, region, year)
      raw = site.data['contests']['regionals'][year][region]['results']

      raw.map do |entry|
        {
          'rank' => entry['rank'],
          'qualified' => entry['qualified'],
          'award' => entry['award'],
          'grade' => entry['grade'],
          'college' => entry['college'],
          'participant' => participants[entry['participant']],
          'school' => schools[entry['school']],
          'tasks' => (entry['tasks'].map(&method(:format_score)) if entry['tasks']),
          'total' => format_score(entry['total']),
        }.compact
      end
    end

    def format_score(score)
      if score % 100 == 0
        (score / 100).to_s
      else
        ('%.2f' % (score / 100.0)).sub('.', ',')
      end
    end
  end
end
