// Copyright (C) 2019-2020 Zilliz. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance
// with the License. You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under the License
// is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
// or implied. See the License for the specific language governing permissions and limitations under the License

#pragma once

#include <map>
#include <string>
#include "common/Types.h"
#include "exceptions/EasyAssert.h"
#include "utils/Json.h"

namespace milvus::segcore {

struct SmallIndexConf {
    std::string index_type;
    nlohmann::json build_params;
    nlohmann::json search_params;
};

class SegcoreConfig {
 private:
    SegcoreConfig() {
        // hard code configurations for small index
        SmallIndexConf sub_conf;
        sub_conf.build_params["nlist"] = 100;
        sub_conf.search_params["nprobe"] = 4;
        sub_conf.index_type = "IVF";
        table_[MetricType::METRIC_L2] = sub_conf;
        table_[MetricType::METRIC_INNER_PRODUCT] = sub_conf;
    }

 public:
    static SegcoreConfig&
    default_config() {
        // TODO: remove this when go side is ready
        static SegcoreConfig config;
        return config;
    }

    void
    parse_from(const std::string& string_path);

    const SmallIndexConf&
    at(MetricType metric_type) const {
        Assert(table_.count(metric_type));
        return table_.at(metric_type);
    }

    int64_t
    get_chunk_rows() const {
        return chunk_rows_;
    }

    void
    set_chunk_rows(int64_t chunk_rows) {
        chunk_rows_ = chunk_rows;
    }

    void
    set_small_index_config(MetricType metric_type, const SmallIndexConf& small_index_conf) {
        table_[metric_type] = small_index_conf;
    }

 private:
    int64_t chunk_rows_ = 32 * 1024;
    std::map<MetricType, SmallIndexConf> table_;
};

}  // namespace milvus::segcore
