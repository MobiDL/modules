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


task achab {
  meta {
		author: "Olivier Ardouin"
		email: "o-ardouin(at)chu-montpellier.fr"
		version: "0.1.0"
		date: "2022-08-18"
	}
  input {
    ## sample specific
    String SampleID
    String OutDir
    String? CaseSample
    String? FatherSample
    String? MotherSample
    Array[String]? Affected
    File mpavcf
    File? PhenolyzerFile
    String? GenesOfInterest
    Float AllelicFrequency = 0.01
    String FilterList = "PASS"
    String? CnvGeneList
    String? CustomVCF
    Float MozaicRate = 0.2
    Int MozaicDP = 5
    Boolean NewHope = false
    String? CustomInfo
    String? FavouriteGeneRef
    String? FilterCustomVCF
    String? FilterCustomVCFRegex
    Boolean AddCustomVCFRegex = false
    Array[String]? PooledSamples
    String? SampleSubset
    Boolean AddCaseDepth = false
    Boolean AddCaseAB = false
    File? IntersectVCF
    File? PoorCoverageFile
    File? Genemap2File
    Boolean skipCaseWT = false
    Boolean HideACMG = false

    ## sytem spécific
    String AchabExe = "wwwachab.pl"
    String PerlExe = "perl"
    ## run time
    Int threads = 1
		Int memoryByThreads = 768
		String? memory
  }

  String Case = if defined(CaseSample) then CaseSample else SampleID
  String Dad = if defined(FatherSample) then "--dad \"~{FatherSample}\" " else ""
  String Mum = if defined(MotherSample) then "--mum \"~{MotherSample}\" " else ""
  String affected = if defined(Affected) then "--affected" else ""
  String candidates = if defined(GenesOfInterest) then "--candidates ~{GenesOfInterest} " else ""
  String cngGL = if defined(CnvGeneList) then "--cnvGeneList ~{CnvGeneList} " else ""
  String hope = if NewHope then "--newHope " else ""
  String customVcf = if defined(CustomVCF) then "--customVCF ~{CustomVCF} " else ""
  String customInfoList = if defined(CustomInfo) then "--customInfoList ~{CustomInfo} " else ""
  String favGenRef = if defined(FavouriteGeneRef) then "--favouriteGeneRef ~{FavouriteGeneRef} " else ""
  String filtCustVcf = if defined(FilterCustomVCF) then "--filterCustomVCF ~{FilterCustomVCF} " else ""
  String filtCustVcfReg = if defined(FilterCustomVCFRegex) then "--filterCustomVCFRegex ~{FilterCustomVCFRegex} " else ""
  String AddCustVCFRegex = if AddCustomVCFRegex then "--addCustomVCFRegex " else ""
  String poolSample = if defined(PooledSamples) then "--pooledSamples" else ""
  String sampSub = if defined(SampleSubset) then "--sampleSubset ~{SampleSubset} " else ""
  String addCasDep = if AddCaseDepth then "--addCaseDepth " else ""
  String addCasab = if AddCaseAB then "--addCaseAB " else ""
  String interVcf = if defined(IntersectVCF) then "--intersectVCF ~{IntersectVCF} " else ""
  String poorCov = if (defined(PoorCoverageFile) && defined(Genemap2File)) then "--poorCoverageFile ~{PoorCoverageFile} --genemap2File ~{Genemap2File} " else ""
  String SkipCase = if skipCaseWT then "--skipCaseWT " else ""
  String Pheno = if defined(PhenolyzerFile) then "--phenolyzerFile ~{PhenolyzerFile} " else ""
  String HideAcmg = if HideACMG then "--hideACMG " else ""

  String Dollar = "$"

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

  command <<<
    set -exo pipefail
    if [[ ! -f ~{OutDir} ]]; then
      mkdir -p ~{OutDir}
    fi

    Pheno=""
    if [[ -f "~{PhenolyzerFile}" ]]; then
      Pheno="--phenolyzerFile ~{PhenolyzerFile}"
    fi

    pool=""
    if [[ "~{poolSample}" != "" ]]; then
      pool="~{poolSample} ~{sep=',' PooledSamples} "
    fi

    if [[ "~{SkipCase}" != "" ]]; then
      if [[ "~{poolSample}" != "" ]]; then
        pool="~{poolSample} ~{Case},~{sep=',' PooledSamples} "
      else
        pool="--pooledSamples ~{Case} "
      fi
    fi

    if [[ "~{affected}" != "" ]]; then
      affect="~{affected} ~{CaseSample},~{sep=',' Affected} "
    else
      affect="--affected ~{CaseSample}"
    fi

    ~{PerlExe} ~{AchabExe} \
      --vcf ~{mpavcf} \
      --outDir ~{OutDir}/ \
      --outPrefix ~{SampleID} \
      --case "~{Case}" \
      ~{Dad} \
      ~{Mum} \
      ~{hope} \
      ~{candidates} \
      ~{Dollar}{Pheno} \
      --popFreqThr "~{AllelicFrequency}" \
      --filterList "~{FilterList}" \
      ~{cngGL} \
      ~{customVcf} \
      --mozaicRate "~{MozaicRate}" \
      --mozaicDP "~{MozaicDP}" \
      ~{customInfoList} \
      ~{favGenRef} \
      ~{filtCustVcf} \
      ~{filtCustVcfReg} \
      ~{AddCustVCFRegex} \
      ~{Dollar}{pool} \
      ~{Dollar}{affect} \
      ~{sampSub} \
      ~{addCasDep} \
      ~{addCasab} \
      ~{interVcf} \
      ~{poorCov} \
      ~{SkipCase} \
      ~{HideAcmg}

  >>>

  output {
File outAchab = "~{OutDir}/~{SampleID}_achab_catch.xlsx"
  }

  runtime {
    cpu: "~{threads}"
    requested_memory_mb_per_core: "${memoryByThreadsMb}"
  }

  parameter_meta{
    SampleID: {
      description: 'Name of sample ID',
      category: 'Required'
    }
    OutDir: {
      description: 'Path of output Directory',
      category: 'Required'
    }
    mpavcf: {
      description: 'VCF mpa processed to parse',
      category: 'Required'
    }
    CaseSample: {
      description: 'Name of Case (use for trios)',
      category: 'Tool option'
    }
    FatherSample: {
      description: 'Name of Father (use for trios)',
      category: 'Tool option'
    }
    MotherSample: {
      description: 'Name of Mother (use for trios)',
      category: 'Tool option'
    }
    Affected: {
      description: 'list of Affected individuals (use when multiple sample in mpa processed vcf file)',
      category: 'Tool option'
    }
    PhenolyzerFile: {
      description: 'phenolyzer output file suffixed by predicted_gene_scores (it will contribute to the final ranking and top50 genes will be  added in METADATA tab)',
      category: 'Tool option'
    }
    GenesOfInterest: {
      description: 'file with end-of-line separated gene symbols of interest (it will create more tabs, if "#myPathology" is present in the  file, a myPathology tab will be created)',
      category: 'Tool option'
    }
    AllelicFrequency: {
      description: 'allelic frequency threshold from 0 to 1 default=0.01 (based on gnomad_genome_ALL)',
      category: 'Tool option'
    }
    FilterList: {
      description: 'comma separated list of VCF FILTER to output (default= \'PASS\', included automatically to the list)',
      category: 'Tool option'
    }
    CnvGeneList: {
      description: 'file with gene symbol + annotation (1 tab-separated), involved by parallel CNV calling',
      category: 'Tool option'
    }
    CustomVCF: {
      description: 'VCF format File with custom annotation (if variant matches then INFO field annotations will be added in new column)',
      category: 'Tool option'
    }
    MozaicRate: {
      description: 'mozaic rate value from 0 to 1, it will color 0/1 genotype according to this value  (default=0.2 as 20%)',
      category: 'Tool option'
    }
    MozaicDP: {
      description: 'ALT variant Depth, number of read supporting ALT, it will give darker color to the 0/1 genotype  (default=5)',
      category: 'Tool option'
    }
    NewHope: {
      description: 'only popFreqThr filter is applied (no more filterList nor MPA_ranking filtering) (default=false)',
      category: 'Tool option'
    }
    CustomInfo: {
      description: 'comma separated list of vcf annotation INFO name (each of them will be added in a new column)',
      category: 'Tool option'
    }
    FavouriteGeneRef: {
      description: 'File with transcript references to extract in a new column (1 transcript by line)',
      category: 'Tool option'
    }
    FilterCustomVCF: {
      description: 'integer value, penalizes variant if its frequency in the customVCF is greater than [value] (default key of info field :  found=[value])',
      category: 'Tool option'
    }
    FilterCustomVCFRegex: {
      description: 'string pattern used as regex to search for a specific field to filter customVCF (default key of info field: \'found=\')',
      category: 'Tool option'
    }
    PooledSamples: {
      description: 'comma separated list of samples that are pooled (it will convert 0/0 genotype into 0/1 if at least 1 read support ALT  base and it will flag cell in yellow, e.g. parents pool in trio context)',
      category: 'Tool option'
    }
    SampleSubset: {
      description: 'comma separated list of samples only processed by Achab to the output>',
      category: 'Tool option'
    }
    AddCaseDepth: {
      description: 'case Depth will be added in a new column (default=false)',
      category: 'Tool option'
    }
    IntersectVCF: {
      description: 'VCF format File for comparison (if variant matches then \'yes\' will be added in a new \'intersectVCF\' column)',
      category: 'Tool option'
    }
    PoorCoverageFile: {
      description: 'poor Coverage File (it will annotate OMIM genes if present in 4th column -requires OMIM genemap2 File- and create an  excel file )',
      category: 'Tool option'
    }
    Genemap2File: {
      description: 'OMIM genemap2 file (it will help to annotate OMIM genes in poor coverage file)',
      category: 'Tool option'
    }
    skipCaseWT: {
      description: 'only if trio mode is activated, it will skip variant if case genotype is 0/0',
      category: 'Tool option'
    }
    AchabExe: {
      description: 'Path used as executable [default: "/mnt/Bioinfo/Softs/src/Captain-ACHAB/wwwachab.pl"]',
      category: 'System'
    }
    PerlExe: {
      description: 'Path used as executable [default: "perl"]',
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

task get_version {
  meta {
    author: "Olivier Ardouin"
    email: "o-ardouin(at)chu-montpellier.fr"
    version: "0.1.0"
    date: "2022-08-18"
  }

  input {
    String AchabExe = "wwwachab.pl"
    String PerlExe = "perl"

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
    ~{PerlExe} ~{AchabExe} --version
  >>>
  
  output {
    String version = read_string(stdout())
  }
  
  runtime {
    cpu: "~{threads}"
    requested_memory_mb_per_core: "${memoryByThreadsMb}"
  }
  
  parameter_meta {
    AchabExe: {
      description: 'Path used as executable [default: "/mnt/Bioinfo/Softs/src/Captain-ACHAB/wwwachab.pl"]',
      category: 'System'
    }
    PerlExe: {
      description: 'Path used as executable [default: "perl"]',
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
