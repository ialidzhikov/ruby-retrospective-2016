RSpec.describe 'Version' do
  def v(version_string)
    Version.new(version_string)
  end

  def expect_error(version)
    expect { v(version) }
      .to raise_error(ArgumentError, "Invalid version string '#{version}'")
  end

  describe '#new' do
    it 'raises ArgumentError when version contains non-numeric symbols' do
      expect_error('1.0-SNAPSHOT')
      expect_error('1.-1')
      expect_error('1.+1')
      expect_error('1.1_000')
    end

    it 'raises ArgumentError when some number is missing' do
      expect_error('.3')
      expect_error('0..3')
      expect_error('3.2.15.')
    end
  end

  describe '#components' do
    it 'can get components with zerolike versions' do
      expect(Version.new.components).to eq []
      expect(v('').components).to eq []
      expect(v('0').components).to eq []
    end

    it 'can get components when version is created via existing one' do
      expect(v(v('1.4.9.16')).components).to eq [1, 4, 9, 16]
    end

    it 'can get components when version has trailing zeros' do
      expect(v('1.2.3.4.0.0').components).to eq [1, 2, 3, 4]
    end

    it 'can get components when given length is equal to version numbers' do
      expect(v('1.4.9.16').components(4)).to eq [1, 4, 9, 16]
    end

    it 'can get components when given length is less than version numbers' do
      expect(v('1.4.9.16').components(3)).to eq [1, 4, 9]
    end

    context 'when given length is bigger than version numbers' do
      it 'can get components ' do
        expect(v('1.4.9.16').components(6)).to eq([1, 4, 9, 16, 0, 0])
      end
    end

    it 'can get components' do
      expect(v('1.4.9.16').components).to eq [1, 4, 9, 16]
    end

    it 'does not allow modification of the class internal state' do
      version = v('1.4.9.16')
      version.components.pop
      expect(version.components).to eq [1, 4, 9, 16]
    end

    it 'does not allow modification of the other class internal state' do
      version = v(v('1.4.9.16'))
      version.components.pop
      expect(version.components).to eq [1, 4, 9, 16]
    end
  end

  describe '<=>' do
    context 'when lengths are equal' do
      it 'knows the bigger version' do
        expect(v('1.4.9.17') <=> v('1.4.9.16')).to eq 1
        expect(v('2.1.1')).to be > v('2.1.0')
        expect(v('2.1.1')).to be >= v('2.0.1')
        expect(v('0.7')).to_not be > v('0.9')
        expect(v('1.0.0.1')).to_not be >= v('1.9.9.9')
      end

      it 'knows the lower version' do
        expect(v('1.4.9.15') <=> v('1.4.9.16')).to eq -1
        expect(v('2.1.1')).to be < v('2.1.7')
        expect(v('2.1.1')).to be <= v('2.2.1')
        expect(v('0.1')).to_not be < v('0.0.0')
        expect(v('1.0.0.1')).to_not be <= v('0.0.0.9')
      end

      it 'knows that versions are equal' do
        other = v('1.4.9.16')
        expect(v('1.4.9.16') <=> other).to eq 0
        expect(v('6.2.0')).to be >= v('6.2.0')
        expect(v('0.2')).to be <= v('0.2')
      end
    end

    context 'when lengths are not equal' do
      it 'knows the bigger version' do
        expect(v('1.4.9.16.8') <=> v('1.4.9.16')).to eq 1
        expect(v('1.5')).to be > v('1.4.9.16')
        expect(v('1.5.3')).to be >= v('1.5')
        expect(v('0.2')).to_not be > v('1.0.9')
        expect(v('0.2')).to_not be >= v('3.1.1')
      end

      it 'knows the lower version' do
        expect(v('1.4.9.15.2.1') <=> v('1.4.9.16')).to eq -1
        expect(v('1.3')).to be < v('1.4.9.16')
        expect(v('1.5.3')).to be <= v('1.6')
        expect(v('0.2')).to_not be < v('0.0.2.9')
        expect(v('0.2')).to_not be <= v('0.1.1.1')
      end

      it 'knows that versions are equal' do
        expect(v('1.4.9.16.0.0') <=> v('1.4.9.16')).to eq 0
        expect(v('4.4.0')).to be >= v('4.4')
        expect(v('2.3.1.0')).to be <= v('2.3.1.0.0')
      end
    end
  end

  describe '#to_s' do
    it 'stringifies' do
      expect(Version.new.to_s).to eq ''
      expect(v('').to_s).to eq ''
      expect(v('0').to_s).to eq ''
    end

    it 'stringifies when major, minor and build numbers are zeros' do
      expect(v('0.1.0.2.0').to_s).to eq '0.1.0.2'
    end

    it 'stringifies' do
      expect(v('1.4.9.16').to_s).to eq '1.4.9.16'
    end
  end

  def expect_range_error(start, last)
    expect { Version::Range.new(start, last) }
      .to raise_error(ArgumentError, "Invalid version string '#{start}'")
  end

  describe 'Version::Range' do
    describe '#new' do
      it 'raises ArgumentError when versions contain non-numeric symbols' do
        expect_range_error('1.0-SNAPSHOT', '1.0-BETA')
        expect_range_error('1.-1', '1.-2')
        expect_range_error('1.+1', '1.+2')
        expect_range_error('1.1_000', '1.2_000')
      end

      it 'raises ArgumentError when some number is missing' do
        expect_range_error('.3', '.3.0')
        expect_range_error('0..3', '0..4')
        expect_range_error('3.2.15.', '3.2.16.')
      end

      it 'can create new instance with zerolike versions' do
        Version::Range.new('', '')
        Version::Range.new('0', '0')
      end

      it 'can create new instance with existing versions' do
        Version::Range.new(Version.new, Version.new)
        Version::Range.new(v('1'), v('1.0.1'))
      end

      it 'can create new instance with strings' do
        Version::Range.new('1', '1.2.3')
      end
    end

    def expect_include_error(range, version)
      expect { range.include?(version) }
        .to raise_error(ArgumentError, "Invalid version string '#{version}'")
    end

    describe '#include?' do
      let(:major_range) { Version::Range.new('1', '2') }

      it 'raises ArgumentError when versions contain non-numeric symbols' do
        expect_include_error(major_range, '1.0-SNAPSHOT')
        expect_include_error(major_range, '1.-1')
        expect_include_error(major_range, '1.+1')
        expect_include_error(major_range, '1.1_000')
      end

      it 'raises ArgumentError when some number is missing' do
        expect_include_error(major_range, '.3')
        expect_include_error(major_range, '0..3')
        expect_include_error(major_range, '3.2.15.')
      end

      it 'can determine whether range includes version' do
        expect(major_range.include?('1.13.9')).to eq true
      end

      it 'can determine whether range does not include' do
        expect(major_range.include?('0.209.9')).to eq false
      end

      it 'includes the interval start to the range' do
        expect(major_range.include?('1')).to eq true
      end

      it 'does not include the interval end to the range' do
        expect(major_range.include?('2')).to eq false
      end
    end

    def map_to_versions(string_versions)
      string_versions.map { |version| v(version) }
    end

    describe '#to_a' do
      it 'can generate versions with starting empty string version' do
        range = Version::Range.new('', '0.0.5')
        expected = map_to_versions [
          '0', '0.0.1', '0.0.2', '0.0.3', '0.0.4'
        ]

        expect(range.to_a).to eq expected
      end

      it 'can generate versions with starting zerolike version' do
        range = Version::Range.new(v('0'), v('0.0.5'))
        expected = map_to_versions [
          '0', '0.0.1', '0.0.2', '0.0.3', '0.0.4'
        ]

        expect(range.to_a).to eq expected
      end

      it 'can generate versions when start equals end' do
        range = Version::Range.new('2.1', '2.1')
        expect(range.to_a).to eq []
      end

      it 'can generate versions to build version' do
        range = Version::Range.new('0.0.8', '0.1')
        expected = map_to_versions ['0.0.8', '0.0.9']

        expect(range.to_a).to eq expected
      end

      it 'can generate versions to minor version' do
        range = Version::Range.new('1', '1.1')
        expected = map_to_versions [
          '1', '1.0.1', '1.0.2', '1.0.3', '1.0.4',
          '1.0.5', '1.0.6', '1.0.7', '1.0.8', '1.0.9'
        ]

        expect(range.to_a).to eq expected
      end

      it 'can generate versions to major version' do
        range = Version::Range.new(v('1.8.9'), v('2.1'))
        expected = map_to_versions [
          '1.8.9', '1.9.0', '1.9.1', '1.9.2', '1.9.3', '1.9.4', '1.9.5',
          '1.9.6', '1.9.7', '1.9.8', '1.9.9', '2', '2.0.1', '2.0.2',
          '2.0.3', '2.0.4', '2.0.5', '2.0.6', '2.0.7', '2.0.8', '2.0.9'
        ]

        expect(range.to_a).to eq expected
      end
    end
  end
end
