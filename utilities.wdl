version 1.0

# MobiDL 2.0 - MobiDL 2 is a collection of tools wrapped in WDL to be used in any WDL pipelines.
# Copyright (C) 2021 MoBiDiC
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.

task findFiles {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.2"
		date: "2021-04-28"
	}

	input {
		String path

		String? regexpName
		String? regexpPath

		Int? maxDepth
		Int? minDepth

		Int? uid
		Int? gid

		Boolean readable = false
		Boolean writable = false
		Boolean executable = false

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String regexpNameOpt = if defined(regexpName) then "-name \"~{regexpName}\" " else ""
	String regexpPathOpt = if defined(regexpPath) then "-path \"~{regexpPath}\" " else ""

	command <<<

		find ~{path} \
			~{default="" "-maxdepth " + maxDepth} \
			~{default="" "-mindepth " + minDepth} \
			~{default="" "-uid " + uid} \
			~{default="" "-gid " + gid} \
			~{true="-readable" false="" readable} \
			~{true="-writable" false="" writable} \
			~{true="-executable" false="" executable} \
			~{regexpPathOpt} \
			~{regexpNameOpt}

	>>>

	output {
		Array[File] files = read_lines(stdout())
	}

	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
	}

	parameter_meta {
		path: {
			description: "Path where find will work on.",
			category: 'Required'
		}
		regexpName: {
			description: "Base of file name (the path with the leading directories removed) matches shell pattern pattern.",
			category: 'Tool option'
		}
		regexpPath: {
			description: "File name matches shell pattern pattern. The metacharacters do not treat `/' or `.' specially.",
			category: 'Tool option'
		}
		maxDepth: {
			description: "Descend at most levels (a non-negative integer) levels of directories below the starting-points.",
			category: 'Tool option'
		}
		minDepth: {
			description: "Do not apply any tests or actions at levels less than levels (a non-negative integer).",
			category: 'Tool option'
		}
		uid: {
			description: "File's numeric user ID is n.",
			category: 'Tool option'
		}
		gid: {
			description: "File's numeric group ID is n.",
			category: 'Tool option'
		}
		readable: {
			description: "Matches files which are readable.",
			category: 'Tool option'
		}
		writable: {
			description: "Matches files which are writable.",
			category: 'Tool option'
		}
		executable: {
			description: "Matches files which are executable and directories which are searchable (in a file name resolution sense).",
			category: 'Tool option'
		}
		threads: {
			description: 'Sets the number of threads [default: 1]',
			category: 'System'
		}
		memory: {
			description: 'Sets the total memory to use ; with suffix M/G [default: (memoryByThreads*threads)M]',
			category: 'System'
		}
		memoryByThreads: {
			description: 'Sets the total memory to use (in M) [default: 768]',
			category: 'System'
		}
	}
}

task convertBedToIntervals {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2020-07-30"
	}

	input {
		File in

		String? outputPath
		String? name

		String ext =".intervals"

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String outputName = if defined(name) then name else sub(basename(in),".bed", "")
	String outputFile = if defined(outputPath) then outputPath + "/" + outputName + ext else outputName + ext

	command <<<

		if [[ ! -d $(dirname ~{outputFile}) ]]; then
			mkdir -p $(dirname ~{outputFile})
		fi

		grep -E -v "^track|^browser|^#" ~{in} | \
		awk -F "\t" '{
			if($2 == $3){
				$3++
			}
			$2++;
			print $1":"$2"-"$3;
		}' > ~{outputFile}

	>>>

	output {
		File outputFile = outputFile
	}

	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
	}

	parameter_meta {
		in: {
			description: 'Input bed to convert.',
			category: 'Required'
		}
		outputPath: {
			description: 'Path where was generated output. [default: "."]',
			category: 'Output path/name option'
		}
		name: {
			description: 'Basename of the output file. [default: sub(basename(in), ".bed")]',
			category: 'Output path/name option'
		}
		ext: {
			description: 'Extension of the output file. [default: ".intervals"]',
			category: 'Output path/name option'
		}
		threads: {
			description: 'Sets the number of threads [default: 1]',
			category: 'System'
		}
		memory: {
			description: 'Sets the total memory to use ; with suffix M/G [default: (memoryByThreads*threads)M]',
			category: 'System'
		}
		memoryByThreads: {
			description: 'Sets the total memory to use (in M) [default: 768]',
			category: 'System'
		}
	}
}

task makeLink {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2020-08-10"
	}

	input {
		File in

		String outputPath
		String? name

		Boolean softLink = false

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String outputName = if defined(name) then name else basename(in)
	String outputFile = outputPath + "/" + outputName

	command <<<

		if [[ ! -d $(dirname ~{outputFile}) ]]; then
			mkdir -p $(dirname ~{outputFile})
		fi

		if [[ ! -f ~{outputFile} ]]; then
			ln \
				~{true="-s" false="" softLink} \
				~{in} \
				~{outputFile}
		else
			1>&2 echo "[WARN][$(date +'%Y-%m-%d')] Link of ~{outputFile} failed : file already exist !"
		fi

	>>>

	output {
		File outputFile = outputFile
	}

	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
	}

	parameter_meta {
		in: {
			description: 'Input bed to convert.',
			category: 'Required'
		}
		outputPath: {
			description: 'Path where was generated output.',
			category: 'Output path/name option'
		}
		name: {
			description: 'Basename of the output file. [default: basename(in)]',
			category: 'Output path/name option'
		}
		softLink: {
			description: 'Make soft link (-s). [default: false]',
			category: 'Tool option'
		}
		threads: {
			description: 'Sets the number of threads [default: 1]',
			category: 'System'
		}
		memory: {
			description: 'Sets the total memory to use ; with suffix M/G [default: (memoryByThreads*threads)M]',
			category: 'System'
		}
		memoryByThreads: {
			description: 'Sets the total memory to use (in M) [default: 768]',
			category: 'System'
		}
	}
}

task concatenateFiles {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.2"
		date: "2021-04-13"
	}

	input {
		String? exe
		Array[File] in

		Boolean gzip = false

		String? outputPath
		String? name
		String subString = "^[0-9]+\-"
		String subStringReplace = ""
		String ext = ".gz"

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	# String baseName = if defined(name) then name else sub(basename(in[0]),subString,subStringReplace)
	# String outputFile = if defined(outputPath) then "~{outputPath}/~{baseName}" else "~{baseName}"

	String cmd_exe = if defined(exe) then exe else if gzip then "zcat" else "cat"
	String compress = if gzip then " | gzip " else ""

	String baseNameTemp = if defined(name) then name else sub(basename(in[0]),subString,subStringReplace)
	String baseName = if gzip then sub(baseNameTemp,ext,"") else "~{baseNameTemp}~{ext}"
	String outputFile = if defined(outputPath) then "~{outputPath}/~{baseName}" else "~{baseName}"

	command <<<
		echo "name: ~{name}"
		echo "baseNameTemp: ~{baseNameTemp}"
		echo "baseName: ~{baseName}"
		if [[ ! -d $(dirname ~{outputFile}) ]]; then
			mkdir -p $(dirname ~{outputFile})
		fi

		~{cmd_exe} ~{sep=" " in} ~{compress} > "~{outputFile}"

	>>>

	output {
		File outputFile = outputFile
	}

	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
	}

	parameter_meta {
		exe: {
			description: 'Executable to launch [Default: cat or zcat].',
			category: 'Required'
		}
		in: {
			description: 'Array of files.',
			category: 'Required'
		}
		gzip: {
			description: 'Switch to the use of zcat (i.e. compressed files on input) [Default: false]',
			category: 'Required'
		}
		outputPath: {
			description: 'Path where output will be generated.',
			category: 'Output path/name option'
		}
		name: {
			description: 'Name of the output file. [default: sub(basename(in[0]),subString,"")]',
			category: 'Output path/name option'
		}
		subString: {
			description: 'Substring to remove to create name file [default: "^[0-9]+\-"]',
			category: 'Output path/name option'
		}
		subStringReplace: {
			description: 'subString replace by this string [default: ""]',
			category: 'Output path/name option'
		}
		threads: {
			description: 'Sets the number of threads [default: 1]',
			category: 'System'
		}
		memory: {
			description: 'Sets the total memory to use ; with suffix M/G [default: (memoryByThreads*threads)M]',
			category: 'System'
		}
		memoryByThreads: {
			description: 'Sets the total memory to use (in M) [default: 768]',
			category: 'System'
		}
	}
}

task wget {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2020-10-05"
	}

	input {
		String path_exe = "wget"

		String in
		String? outputPath
		String? name
		String subString = ".*/(.*)$"
		String subStringReplace = "$1"

		Boolean forceHTML = false
		File? configuration
		Boolean timestamping = false
		String? user
		String? password
		Boolean recursive = false
		Int? recursiveLVL
		Boolean convertLinks = false
		Boolean mirror = false
		Boolean pageRequisites = false

		Array[String]? extAccept
		Array[String]? extReject
		Array[String]? repAccept
		Array[String]? repReject

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String baseName = if defined(name) then name else sub(in,subString,subStringReplace)
	String outputFile = if defined(outputPath) then "~{outputPath}/~{baseName}" else "~{baseName}"

	Boolean extAcceptDefined = defined(extAccept)
	Boolean extRejectDefined = defined(extReject)
	Boolean repAcceptDefined = defined(repAccept)
	Boolean repRejectDefined = defined(repReject)

	command <<<

		if [[ ! -d $(dirname ~{outputFile}) ]]; then
			mkdir -p $(dirname ~{outputFile})
		fi

		~{path_exe} \
			~{true="--force-html" false="" forceHTML} \
			~{default="" "--config " + configuration} \
			~{true="--timestamping" false="" timestamping} \
			~{default="" "--user " + user} \
			~{default="" "--password " + password} \
			~{true="--recursive" false="" recursive} \
			~{default="" "--level " + recursiveLVL} \
			~{true="--convert-links" false="" convertLinks} \
			~{true="--mirror" false="" mirror} \
			~{true="--page-requisites" false="" pageRequisites} \
			~{true="--accept" false="" extAcceptDefined} ~{default="" sep="," extAccept} \
			~{true="--reject" false="" extRejectDefined} ~{default="" sep="," extReject} \
			~{true="--include-directories" false="" repAcceptDefined} ~{default="" sep="," repAccept} \
			~{true="--exclude-directories" false="" repRejectDefined} ~{default="" sep="," repReject} \
			~{in} \
			-O ~{outputFile}

	>>>

	output {
		File outputFile = outputFile
	}

	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
	}

	parameter_meta {
		path_exe: {
			description: 'Path used as executable [default: "wget"]',
			category: 'System'
		}
		in: {
			description: 'Url of the input file.',
			category: 'Required'
		}
		outputPath: {
			description: 'Path where output will be generated.',
			category: 'Output path/name option'
		}
		name: {
			description: 'Name of the output file. [default: sub(basename(in),subString,subStringReplace)]',
			category: 'Output path/name option'
		}
		subString: {
			description: 'Substring to remove to create name file [default: ".*/(.*)$"]',
			category: 'Output path/name option'
		}
		subStringReplace: {
			description: 'subString replace by this string [default: "$1"]',
			category: 'Output path/name option'
		}
		forceHTML: {
			description: 'Force to resolve inputs as HTML [default: false]',
			category: 'Tool option'
		}
		configuration: {
			description: 'Use a specific config file.',
			category: 'Tool option'
		}
		timestamping: {
			description: 'Do not download files if they are not more recent than locally [default: false]',
			category: 'Tool option'
		}
		user: {
			description: 'Define the user for FTP and HTTP (use with caution because it will appear in clear)',
			category: 'Tool option'
		}
		password: {
			description: 'Define the password for FTP and HTTP (use with caution because it will appear in clear)',
			category: 'Tool option'
		}
		recursive: {
			description: 'Turn on/off recursive mode [default: false]',
			category: 'Tool option'
		}
		recursiveLVL: {
			description: 'Level of maximal recursivity',
			category: 'Tool option'
		}
		convertLinks: {
			description: 'Convert links locally into HTML and CSS [default: false]',
			category: 'Tool option'
		}
		mirror: {
			description: 'Activate timestamping and recursive to infinity [default: false]',
			category: 'Tool option'
		}
		pageRequisites: {
			description: 'Get all images and others to display HTML pages [default: false]',
			category: 'Tool option'
		}
		extAccept: {
			description: 'Array of accepted extensions.',
			category: 'Tool option'
		}
		extReject: {
			description: 'Array of rejected extensions.',
			category: 'Tool option'
		}
		repAccept: {
			description: 'Array of accepted directories.',
			category: 'Tool option'
		}
		repReject: {
			description: 'Array of rejected directories.',
			category: 'Tool option'
		}
		threads: {
			description: 'Sets the number of threads [default: 1]',
			category: 'System'
		}
		memory: {
			description: 'Sets the total memory to use ; with suffix M/G [default: (memoryByThreads*threads)M]',
			category: 'System'
		}
		memoryByThreads: {
			description: 'Sets the total memory to use (in M) [default: 768]',
			category: 'System'
		}
	}
}

task gzip {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2020-10-06"
	}

	input {
		String path_exe = "gzip"

		String in
		String? outputPath
		String? name
		String subString = ""
		String subStringReplace = ""
		String ext = ".gz"

		Boolean decompress = false
		Int levelCompression = 6
		Boolean recursive = false

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String baseNameTemp = if defined(name) then name else sub(basename(in),subString,subStringReplace)
	String baseName = if decompress then sub(baseNameTemp,ext,"") else "~{baseNameTemp}~{ext}"
	String outputFile = if defined(outputPath) then "~{outputPath}/~{baseName}" else "~{baseName}"

	command <<<

		if [[ ! -d $(dirname ~{outputFile}) ]]; then
			mkdir -p $(dirname ~{outputFile})
		fi

		~{path_exe} \
			~{true="--decompress" false="" decompress} \
			-~{levelCompression} \
			--stdout \
			~{in} \
			> ~{outputFile}

	>>>

	output {
		File outputFile = outputFile
	}

	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
	}

	parameter_meta {
		path_exe: {
			description: 'Path used as executable [default: "gzip"]',
			category: 'System'
		}
		in: {
			description: 'Path of the input file.',
			category: 'Required'
		}
		outputPath: {
			description: 'Path where output will be generated.',
			category: 'Output path/name option'
		}
		name: {
			description: 'Name of the output file. [default: sub(basename(in),subString,subStringReplace)]',
			category: 'Output path/name option'
		}
		subString: {
			description: 'Substring to remove to create name file [default: ""]',
			category: 'Output path/name option'
		}
		subStringReplace: {
			description: 'subString replace by this string [default: ""]',
			category: 'Output path/name option'
		}
		ext: {
			description: 'Extension of the output (compress) or input (decompress) file [default: ".gz"]',
			category: 'Tool option'
		}
		decompress: {
			description: 'Enable decompression mode [default: false]',
			category: 'System'
		}
		levelCompression: {
			description: 'Set compression level [default: 6]',
			category: 'System'
		}
		threads: {
			description: 'Sets the number of threads [default: 1]',
			category: 'System'
		}
		memory: {
			description: 'Sets the total memory to use ; with suffix M/G [default: (memoryByThreads*threads)M]',
			category: 'System'
		}
		memoryByThreads: {
			description: 'Sets the total memory to use (in M) [default: 768]',
			category: 'System'
		}
	}
}

task sortgtf {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2020-12-01"
		source: "https://www.biostars.org/p/306859/#306895"
	}

	input {
		String in
		String? outputPath
		String? name
		String subString = ".(gtf|gff)$"
		String subStringReplace = ".sorted.$1"

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String baseName = if defined(name) then name else sub(basename(in),subString,subStringReplace)
	String outputFile = if defined(outputPath) then "~{outputPath}/~{baseName}" else "~{baseName}"

	command <<<

		if [[ ! -d $(dirname ~{outputFile}) ]]; then
			mkdir -p $(dirname ~{outputFile})
		fi

		(grep -v "Parent=" ~{in}|sort -k1,1 -k4,4n -k5,5n;grep "Parent=" ~{in}|sort -k1,1 -k4,4n -k5,5n)| sort -k1,1 -k4,4n -s > ~{outputFile}

	>>>

	output {
		File outputFile = outputFile
	}

	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
	}

	parameter_meta {
		in: {
			description: 'Path of the input file.',
			category: 'Required'
		}
		outputPath: {
			description: 'Path where output will be generated.',
			category: 'Output path/name option'
		}
		name: {
			description: 'Name of the output file. [default: sub(basename(in),subString,subStringReplace)]',
			category: 'Output path/name option'
		}
		subString: {
			description: 'Substring to remove to create name file [default: ".(gtf|gff)$"]',
			category: 'Output path/name option'
		}
		subStringReplace: {
			description: 'subString replace by this string [default: ".sorted.$1"]',
			category: 'Output path/name option'
		}
		threads: {
			description: 'Sets the number of threads [default: 1]',
			category: 'System'
		}
		memory: {
			description: 'Sets the total memory to use ; with suffix M/G [default: (memoryByThreads*threads)M]',
			category: 'System'
		}
		memoryByThreads: {
			description: 'Sets the total memory to use (in M) [default: 768]',
			category: 'System'
		}
	}
}

task fai2bed {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2020-12-07"
		source: "https://bioinformatics.stackexchange.com/questions/91/how-to-convert-fasta-to-bed#answer-108"
	}

	input {
		String in
		String? outputPath
		String? name
		String subString = "\.?(fa)?(sta)?\.fai$"
		String subStringReplace = ".bed"

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String baseName = if defined(name) then name else sub(basename(in),subString,subStringReplace)
	String outputFile = if defined(outputPath) then "~{outputPath}/~{baseName}" else "~{baseName}"

	command <<<

		if [[ ! -d $(dirname ~{outputFile}) ]]; then
			mkdir -p $(dirname ~{outputFile})
		fi

		awk 'BEGIN {FS="\t"}; {print $1 FS "0" FS $2}' ~{in} > ~{outputFile}

	>>>

	output {
		File outputFile = outputFile
	}

	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
	}

	parameter_meta {
		in: {
			description: 'Path of the input file.',
			category: 'Required'
		}
		outputPath: {
			description: 'Path where output will be generated.',
			category: 'Output path/name option'
		}
		name: {
			description: 'Name of the output file. [default: sub(basename(in),subString,subStringReplace)]',
			category: 'Output path/name option'
		}
		subString: {
			description: 'Substring to remove to create name file [default: "\.?(fa)?(sta)?\.fai$"]',
			category: 'Output path/name option'
		}
		subStringReplace: {
			description: 'subString replace by this string [default: ".bed"]',
			category: 'Output path/name option'
		}
		threads: {
			description: 'Sets the number of threads [default: 1]',
			category: 'System'
		}
		memory: {
			description: 'Sets the total memory to use ; with suffix M/G [default: (memoryByThreads*threads)M]',
			category: 'System'
		}
		memoryByThreads: {
			description: 'Sets the total memory to use (in M) [default: 768]',
			category: 'System'
		}
	}
}

task nanoVar2Bed {
	meta {
		author: "Thomas GUIGNARD"
		email: "t-guignard(at)chu-montpellier.fr"
		version: "0.0.3"
		date: "2021-04-06"
	}

	input {
		File inputNanovar
		String? outputPath
		String? name
		String subString = "\.tsv$"
		String subStringReplace = "_igv_sorted.bed"

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String baseName = if defined(name) then name else sub(basename(inputNanovar),subString,subStringReplace)
	String outputFile = if defined(outputPath) then "~{outputPath}/~{baseName}" else "~{baseName}"

	command <<<

		if [[ ! -d ~{outputPath} ]]; then
			mkdir -p ~{outputPath}
		fi

		awk 'BEGIN{OFS="\t"}{print $1,$2,$2+$3,$5,$12,$8,$2,$2+$3}' ~{inputNanovar} |
		awk -F '\t' -v OFS='\t' '{y=$1"\t"$2"\t"$4; a[y]=$0}END{for (y in a) print a[y]}' |
		awk -F '\t' -v OFS='\t' '{
			x=$4;
			y=$1"\t"$2"\t"$3"\t"$4;
			d[y]=$1"\t"$2"\t"$3;
			b[y]=$4;c[y]=$5"\t"$6"\t"$7"\t"$8;
			if(a[x] !~ $1":"){ g[x]=g[x]+1};
			a[x]=a[x]"~"$1":"$2"-"$3;
			f[x]=f[x]+1
		}END{
			for (y in b ){
				if (f[b[y]] == 1 ) {
					print d[y],b[y]""a[b[y]],c[y],"100,100,100"
				} else {
					if (f[b[y]] == 2 ) {
						if (g[b[y]] == 1) {
							print d[y],b[y]""a[b[y]],c[y],"0,0,255"
						} else {
							print d[y],b[y]""a[b[y]],c[y],"255,0,0"
						}
					} else {
						if (f[b[y]] >= 3 ) {
							if (g[b[y]] == 1) {
								print d[y],b[y]""a[b[y]],c[y],"0,255,0"
							} else {
								if(g[b[y]] < f[b[y]] && g[b[y]]==2) {
									print d[y],b[y]""a[b[y]],c[y],"255,0,0"
								} else{
									print d[y],b[y]""a[b[y]],c[y],"255,127,0"
								}
							}
						}
					}
				}
			}
		}' | sort -k1,1 -k2,2n > ~{outputFile}

	>>>

	output {
		File outputFile = outputFile
	}

	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
	}

	parameter_meta {
		inputNanovar: {
			description: 'Path to the input of NanoVar',
			category: 'Required'
		}
		outputPath: {
			description: 'Path where output will be generated.',
			category: 'Output path/name option'
		}
		name: {
			description: 'Name of the output file. [default: sub(basename(in),subString,subStringReplace)]',
			category: 'Output path/name option'
		}
		subString: {
			description: 'Substring to remove to create name file [default: "\.tsv$"]',
			category: 'Output path/name option'
		}
		subStringReplace: {
			description: 'subString replace by this string [default: "_igv_sorted.bed"]',
			category: 'Output path/name option'
		}
		threads: {
			description: 'Sets the number of threads [default: 1]',
			category: 'System'
		}
		memory: {
			description: 'Sets the total memory to use ; with suffix M/G [default: (memoryByThreads*threads)M]',
			category: 'System'
		}
		memoryByThreads: {
			description: 'Sets the total memory to use (in M) [default: 768]',
			category: 'System'
		}
	}
}

task bed2Array {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2021-04-06"
	}

	input {
		File bed

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	command <<<
		awk 'BEGIN{OFS="\t"; print "chrom","start","end"}{print $1,$2,$3}' ~{bed}
	>>>

	output {
		Array[Object] bedObj = read_objects(stdout())
	}

	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
	}

	parameter_meta {
		bed: {
			description: 'Path to the input of NanoVar',
			category: 'Required'
		}
		threads: {
			description: 'Sets the number of threads [default: 1]',
			category: 'System'
		}
		memory: {
			description: 'Sets the total memory to use ; with suffix M/G [default: (memoryByThreads*threads)M]',
			category: 'System'
		}
		memoryByThreads: {
			description: 'Sets the total memory to use (in M) [default: 768]',
			category: 'System'
		}
	}
}

task bedPrimer2woutPrimer {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2021-04-06"
	}

	input {
		File bed

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	command <<<
		awk 'BEGIN{OFS="\t"}{print $1,$7,$8,$4,$5,$6}' ~{bed}
	>>>

	output {
		File bedWoutPrimer = stdout()
	}

	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
	}

	parameter_meta {
		bed: {
			description: 'Path to the input bed',
			category: 'Required'
		}
		threads: {
			description: 'Sets the number of threads [default: 1]',
			category: 'System'
		}
		memory: {
			description: 'Sets the total memory to use ; with suffix M/G [default: (memoryByThreads*threads)M]',
			category: 'System'
		}
		memoryByThreads: {
			description: 'Sets the total memory to use (in M) [default: 768]',
			category: 'System'
		}
	}
}

task getColumn {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.2"
		date: "2021-05-10"
	}

	input {
		File in

		String ofs = "\\t"
		String fs = "\\t"
		Array[Int] column = [1]
		Boolean uniq = false

		String? reSkip
		String? reKept
		Int? columnSkip
		Int? columnKept


		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	command <<<
		awk -v reskip='~{default="\\!." reSkip}' -v rekept='~{default="." reKept}' \
			'BEGIN{FS="~{fs}";OFS="~{ofs}"}{
			if ($~{default="0" columnSkip} ~ reskip) { next };
			if ($~{default="0" columnKept} ~ rekept) { print $~{sep=",$" column}; };

		}' ~{in} ~{true="| uniq" false="" uniq}
	>>>

	output {
		Array[String] columns = read_lines(stdout())
	}

	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
	}

	parameter_meta {
		in: {
			description: 'Path to the input file',
			category: 'Required'
		}
		ofs: {
			description: 'Output field separator [default: tabulation (\\t)]',
			category: 'Tool option'
		}
		ofs: {
			description: 'Field separator [default: tabulation (\\t)]',
			category: 'Tool option'
		}
		column: {
			description: 'Column(s) to get [default: 1]',
			category: 'Tool option'
		}
		reSkip: {
			description: 'Skip lines with this regexp on columnSkip [default: none]',
			category: 'Tool option'
		}
		reKept: {
			description: 'Kept only lines with this regexp on columnKept [default: all]',
			category: 'Tool option'
		}
		columnSkip: {
			description: 'Column where regexp reSkip is tested [default: 0 - i.E. test on full line]',
			category: 'Tool option'
		}
		columnKept: {
			description: 'Column where regexp reKept is tested [default: 0 - i.E. test on full line]',
			category: 'Tool option'
		}
		uniq: {
			description: 'Get uniq value only [default: false]',
			category: 'Tool option'
		}
		threads: {
			description: 'Sets the number of threads [default: 1]',
			category: 'System'
		}
		memory: {
			description: 'Sets the total memory to use ; with suffix M/G [default: (memoryByThreads*threads)M]',
			category: 'System'
		}
		memoryByThreads: {
			description: 'Sets the total memory to use (in M) [default: 768]',
			category: 'System'
		}
	}
}

task filterBEDOnName {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.2"
		date: "2021-05-14"
	}

	input {
		File in

		Array[String] names
		Int? nbCol

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	command <<<
		python <<CODE
		retained_regions = ["~{sep='","' names}"]
		nb_col = ~{default="None" nbCol}

		with open("~{in}") as FH_in:
			for line in FH_in:
				if line.startswith("browser ") or line.startswith("track ") or line.startswith("#"):
					print(line.rstrip())
				else:
					fields = [field.strip() for field in line.split("\t")]
					if fields[3] in retained_regions:
						if nb_col is not None:
							line = "\t".join(fields[:nb_col])
						print(line.rstrip())
		CODE
	>>>

	output {
		File outputFile = stdout()
	}

	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
	}

	parameter_meta {
		in: {
			description: 'Path to the input file',
			category: 'Required'
		}
		names: {
			description: 'List of names of the retained regions.',
			category: 'Required'
		}
		nbCol: {
			description: 'Number of columns in output.',
			category: 'Tool Option'
		}
		threads: {
			description: 'Sets the number of threads [default: 1]',
			category: 'System'
		}
		memory: {
			description: 'Sets the total memory to use ; with suffix M/G [default: (memoryByThreads*threads)M]',
			category: 'System'
		}
		memoryByThreads: {
			description: 'Sets the total memory to use (in M) [default: 768]',
			category: 'System'
		}
	}
}

task computePoorCoverage {
	meta {
		author: "Olivier ARDOUIN"
		email: "o-ardouin(at)chu-montpellier.fr"
		version: "0.0.2"
		date: "2021-10-11"
	}

	input {
		File BamFile
		File IntervalBedFile
		Int BedtoolsLowCoverage = 30
		Int BedToolsSmallInterval = 20
		String GenomeVersion = "hg19"

		String? outputPath
		String? name
		String ext = ".LowCoverage.tsv"

		String BedToolsExe = "bedtools"
		String AwkExe = "awk"
		String SortExe = "sort"

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String baseName = if defined(name) then name else sub(basename(BamFile),"(.*)\.(sam|bam|cram)$","$1")
	String outputFile = if defined(outputPath) then "~{outputPath}/~{baseName}~{ext}" else "~{baseName}~{ext}"

	command <<<
		if [[ ! -d $(dirname ~{outputFile}) ]]; then
			mkdir -p $(dirname ~{outputFile})
		fi

		~{BedToolsExe} genomecov -ibam ~{BamFile} -bga \
		| ~{AwkExe} -v low_coverage="~{BedtoolsLowCoverage}" '$4<low_coverage' \
		| ~{BedToolsExe} intersect -a ~{IntervalBedFile} -b - \
		| ~{SortExe} -k1,1 -k2,2n -k3,3n \
		| ~{BedToolsExe} merge -c 4 -o distinct -i - \
		| ~{AwkExe} -v small_intervall="~{BedToolsSmallInterval}" \
		'BEGIN {OFS="\t";print "#chr","start","end","region","size bp","type","UCSC link"} {a=($3-$2+1);if(a<small_intervall) {b="SMALL_INTERVAL"} else {b="OTHER"};url="http://genome-euro.ucsc.edu/cgi-bin/hgTracks?db='~{GenomeVersion}'&position="$1":"$2-10"-"$3+10"&highlight='~{GenomeVersion}'."$1":"$2"-"$3;print $0, a, b, url}' > "~{outputFile}"
	>>>

	output {
		File poorCoverageFile = "~{outputFile}"
	}

	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
	}
}

task computeCoverage {
	meta {
		author: "Olivier ARDOUIN"
		email: "o-ardouin(at)chu-montpellier.fr"
		version: "0.0.2"
		date: "2021-10-11"
	}

	input {

		File BedCovFile

		String? outputPath
		String? name

		String ext = ".Coverage.tsv"

		String AwkExe = "awk"
		String SortExe = "sort"

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String baseName = if defined(name) then name else sub(basename(BedCovFile),".bed","$1")
	String outputFile = if defined(outputPath) then "~{outputPath}/~{baseName}~{ext}" else "~{baseName}~{ext}"

	command <<<
		if [[ ! -d $(dirname ~{outputFile}) ]]; then
			mkdir -p $(dirname ~{outputFile})
		fi

		~{SortExe} -k1,1 -k2,2n -k3,3n ~{BedCovFile} \
		| ~{AwkExe} 'BEGIN {OFS="\t"}{a=($3-$2+1);b=($7/a);print $1,$2,$3,$4,b,"+","+"}' \
		> "~{outputFile}"
	>>>
	output {
		File TsvCoverageFile = "~{outputFile}"
	}
	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
	}
}

task computePoorCoverageExtended {
	meta {
		author: "Thomas Guignard"
		email: "t-guignard(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2021-11-15"
	}

	input {
		String path_exe = "bedtools"

		File BamFile
		File intervalBedFile
		String PoorCoverageFileFolder
		File CoverageFile

		Int BedtoolsLowCoverage = 10
		Int BedToolsSmallInterval = 5

		String genomeVersion = "hg19"

		String? outputPath
		String? name
		String ext = ".PoorCoverage_extended.tsv"

		String ofs = "\\t"
		String fs = "\\t"

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String baseName = if defined(name) then name else sub(basename(BamFile),"(.*)\.(sam|bam|cram)$","$1")
	String outputFile = if defined(outputPath) then "~{outputPath}/~{baseName}~{ext}" else "~{baseName}~{ext}"

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	command <<<

		~{path_exe} genomecov -ibam ~{BamFile} -bga \
		| awk -v low_coverage="~{BedtoolsLowCoverage}" '$4<low_coverage' \
		| ~{path_exe} intersect -wb -a ~{intervalBedFile} -b - \
		| sort -k1,1 -k2,2n -k3,3n \
		| ~{path_exe} merge -d 1 -c 4,10,10 -o distinct,min,max -i - \
		| ~{path_exe} intersect -loj -c -a -  -b ~{PoorCoverageFileFolder}/*.tsv  \
		| ~{path_exe} intersect -wb -loj -a -  -b ~{CoverageFile}  \
		| awk -v small_intervall="~{BedToolsSmallInterval}" -v genomeVersion="~{genomeVersion}" \
		'BEGIN {OFS="~{ofs}";print "#chr","start","end","gene","region","region_size","type","MIN_COV","MAX_COV","Occurrence","ROI_MEAN_COV","UCSC link"} {split($4,gene,":");a=($3-$2+1);if(a<small_intervall) {b="SMALL_INTERVAL"} else {b="OTHER"};url="http://genome-euro.ucsc.edu/cgi-bin/hgTracks?db='genomeVersion'&position="$1":"$2-10"-"$3+10"&highlight='genomeVersion'."$1":"$2"-"$3; print $1,$2,$3,gene[1],$4,a, b,$5,$6,$7,$12, url}' \
		> ~{outputFile}

	>>>

	output {
		File poorCoverageFile = outputFile
	}

	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
	}
	parameter_meta {
		path_exe: {
			description: 'Path to the BedTools exe',
			category: 'Required'
		}
		BamFile: {
			description: 'Bam file to process',
			category: 'Required'
		}
		intervalBedFile: {
			description: 'Bed file, need to be merged',
			category: 'Required'
		}
		PoorCoverageFileFolder: {
			description: 'TSV file directory, output from computePoorCoverage, done with the same BAM and the same intervalBedFile',
			category: 'Required'
		}
		CoverageFile: {
			description: 'TSV file, output from computeCoverage, done with the same BAM and the same intervalBedFile',
			category: 'Required'
		}
		BedtoolsLowCoverage: {
			description: 'Limit value for define cow coverage target [default = 10]',
			category: 'Optional value'
		}
		BedToolsSmallInterval: {
			description: 'Limit value for define max size for tagging poor coverage area [default = 5]',
			category: 'Optional value'
		}
		genomeVersion: {
			description: 'Genome version used [default = hg19]',
			category: 'Optional value'
		}
		outputPath: {
			description: 'Path for outputFile [default = ./]',
			category: 'Optional value'
		}
		name: {
			description: 'Sample Name, if not supply infered form bam file name',
			category: 'Optional value'
		}
		ext: {
			description: 'extension for outputFile [default = .PoorCoverage_extended.tsv]',
			category: 'Optional value'
		}
	}
}

task computeCoverageClamms {
	meta {
		author: "Olivier ARDOUIN"
		email: "o-ardouin(at)chu-montpellier.fr"
		version: "0.0.2"
		date: "2021-10-11"
	}

	input {
		File BedCovFile

		String? outputPath
		String? name

		String ext = ".coverage.bed"

		String AwkExe = "awk"
		String SortExe = "sort"

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String baseName = if defined(name) then name else sub(basename(BedCovFile),".bed","$1")
	String outputFile = if defined(outputPath) then "~{outputPath}/~{baseName}~{ext}" else "~{baseName}~{ext}"

	command <<<
		if [[ ! -d $(dirname ~{outputFile}) ]]; then
			mkdir -p $(dirname ~{outputFile})
		fi

		~{SortExe} -k1,1 -k2,2n -k3,3n ~{BedCovFile} \
		| ~{AwkExe} '{ printf "%s\t%d\t%d\t%.6g\n", $1, $2, $3, $NF/($3-$2); }' \
		> "~{outputFile}"
	>>>
	output {
		File ClammsCoverageFile = "~{outputFile}"
	}
	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
	}
}

task BamReadByChromosomes {
	meta {
		author: "Olivier ARDOUIN"
		email: "o-ardouin(at)chu-montpellier.fr"
		version: "0.0.2"
		date: "2021-10-11"
	}

	input {
		File in

		String? outputPath
		String? name

		String ext = ".readByChrom.tsv"

		String samtoolsExe = "samtools"
		String cutExe = "cut"
		String uniqExe = "uniq"

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String baseName = if defined(name) then name else sub(basename(in),"(.*)\.(sam|bam|cram)$","$1")
	String outputFile = if defined(outputPath) then "~{outputPath}/~{baseName}~{ext}" else "~{baseName}~{ext}"

	command <<<
		if [[ ! -d $(dirname ~{outputFile}) ]]; then
			mkdir -p $(dirname ~{outputFile})
		fi

		~{samtoolsExe} view ~{in} \
		| ~{cutExe} -f 3 \
		| ~{uniqExe} -c \
		> "~{outputFile}"
	>>>

	output {
		File ReadCountByChrom = "~{outputFile}"
	}

	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
	}
}

task printStringtoFile {
	meta {
		author: "Olivier ARDOUIN"
		email: "o-ardouin(at)chu-montpellier.fr"
		version: "0.0.2"
		date: "2021-10-27"
	}

	input {
		String in
		String outFile

		Boolean Append = false

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String to = if Append then ">>" else ">"

	command <<<
		set exo pipefail
		if [[ ! -d $(dirname ~{outFile}) ]]; then
			mkdir -p $(dirname ~{outFile})
		fi
		echo "~{in}" ~{to} ~{outFile}
		echo "----" >> ~{outFile}
	>>>

	output {
		File out = "~{outFile}"
	}

	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
	}
}

task printSoftVersion {
	meta {
		author: "Olivier ARDOUIN"
		email: "o-ardouin(at)chu-montpellier.fr"
		version: "0.0.3"
		date: "2022-08-31"
	}

	input {
		Array[String] Soft
		String outFile

		Boolean Append = false

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String to = if Append then ">>" else ">"

	command <<<
		set exo pipefail
		if [[ ! -d $(dirname ~{outFile}) ]]; then
			mkdir -p $(dirname ~{outFile})
		fi
		date ~{to} ~{outFile}
		echo -e "~{sep='\n---\n' Soft}" >> ~{outFile}
		echo "----" >> ~{outFile}
	>>>

	output {
		File out = "~{outFile}"
	}

	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
	}
}

task mkDir {
	meta {
		author: "Olivier Ardouin"
		email: "o-ardouin(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2022-08-22"
	}

	input {
		String outputPath

		Int threads = 1
		Int memoryByThreads = 768
	}

	command <<<
		set -exo pipefail
		if [[ ! -d "~{outputPath}" ]]; then mkdir -p "~{outputPath}"; fi
	>>>

	output {
		Boolean DirCreated = true
		String output_Path = "~{outputPath}"
	}

	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreads}"
	}

	parameter_meta {
		outputPath: {
			description: 'Path of the directory to create',
			category: 'Output path/name option'
		}
		threads: {
			description: 'Sets the number of threads [default: 1]',
			category: 'System'
		}
		memoryByThreads: {
			description: 'Sets the total memory to use (in M) [default: 768]',
			category: 'System'
		}
	}
}

task rm_files {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2026-07-15"
	}

	input {
		Array[String] files

		Int threads = 1
		Int memoryByThreads = 768
	}

	command <<<
		declare -a arr=("~{sep='" "' files}") 
		for f in "${arr[@]}"; do 
			if [ -d ${f} ]; then
				rm -r "${f}"
			else
				rm "${f}"
			fi
		done
	>>>

	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreads}"
	}

	parameter_meta {
		files: {
			description: 'Array of files/directory to remove',
			category: 'Input'
		}
		threads: {
			description: 'Sets the number of threads [default: 1]',
			category: 'System'
		}
		memoryByThreads: {
			description: 'Sets the total memory to use (in M) [default: 768]',
			category: 'System'
		}
	}
}
